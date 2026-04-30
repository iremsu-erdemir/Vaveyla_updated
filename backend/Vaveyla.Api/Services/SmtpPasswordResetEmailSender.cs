using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;
using Vaveyla.Api.Models;

namespace Vaveyla.Api.Services;

public sealed class SmtpPasswordResetEmailSender : IPasswordResetEmailSender
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<SmtpPasswordResetEmailSender> _logger;

    public SmtpPasswordResetEmailSender(
        IOptions<EmailSettings> emailSettings,
        ILogger<SmtpPasswordResetEmailSender> logger)
    {
        _emailSettings = emailSettings.Value;
        _logger = logger;
    }

    public async Task SendResetCodeAsync(string toEmail, string resetCode, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_emailSettings.SmtpHost) ||
            string.IsNullOrWhiteSpace(_emailSettings.FromAddress))
        {
            throw new InvalidOperationException("Email settings are missing. Configure Email:SmtpHost and Email:FromAddress.");
        }

        // Gmail app passwords are 16 chars; Google often shows them with spaces — SMTP auth expects no spaces.
        var username = _emailSettings.Username?.Trim() ?? string.Empty;
        var password = (_emailSettings.Password ?? string.Empty).Replace(" ", string.Empty);

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(_emailSettings.FromName, _emailSettings.FromAddress));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = "Vaveyla - Sifre Sifirlama Dogrulama Kodu";
        message.Body = new TextPart("plain") { Text = BuildBody(resetCode) };

        var secureSocket = ResolveSecureSocketOptions(_emailSettings.SmtpPort, _emailSettings.EnableSsl);

        using var client = new SmtpClient();
        await client.ConnectAsync(
            _emailSettings.SmtpHost,
            _emailSettings.SmtpPort,
            secureSocket,
            cancellationToken);

        if (!string.IsNullOrWhiteSpace(username))
        {
            await client.AuthenticateAsync(username, password, cancellationToken);
        }

        await client.SendAsync(message, cancellationToken);
        await client.DisconnectAsync(true, cancellationToken);

        _logger.LogInformation("Password reset code e-mail sent to {Email}.", toEmail);
    }

    private static SecureSocketOptions ResolveSecureSocketOptions(int port, bool enableSsl)
    {
        if (!enableSsl)
        {
            return SecureSocketOptions.None;
        }

        return port == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
    }

    private static string BuildBody(string resetCode)
    {
        return
            "Sifre sifirlama talebiniz alindi.\n\n" +
            $"Dogrulama kodunuz: {resetCode}\n\n" +
            "Bu kod 10 dakika boyunca gecerlidir.\n" +
            "Eger bu islemi siz yapmadiysaniz bu e-postayi dikkate almayabilirsiniz.";
    }
}
