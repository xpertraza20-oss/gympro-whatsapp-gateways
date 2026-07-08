'use strict';
const nodemailer = require('nodemailer');

/**
 * Generates a secure numeric OTP string of a given length.
 * @param {number} length - 4 or 6
 * @returns {string}
 */
const generateOtp = (length = 6) => {
  const min = Math.pow(10, length - 1);
  const max = Math.pow(10, length) - 1;
  return String(Math.floor(min + Math.random() * (max - min + 1)));
};

/**
 * Returns a configured Nodemailer transporter.
 * Reads credentials from environment variables.
 * Falls back to Ethereal (email sandbox) in development when credentials are absent.
 */
const createTransporter = async () => {
  // Production: use real SMTP credentials from environment
  if (
    process.env.SMTP_HOST &&
    process.env.SMTP_USER &&
    process.env.SMTP_PASS
  ) {
    return nodemailer.createTransport({
      host: process.env.SMTP_HOST,
      port: Number(process.env.SMTP_PORT) || 587,
      secure: process.env.SMTP_SECURE === 'true', // true for port 465
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });
  }

  // Development fallback: create a temporary Ethereal test account
  const testAccount = await nodemailer.createTestAccount();
  console.log('📧 [Nodemailer] Using Ethereal test account:');
  console.log(`   User: ${testAccount.user}`);
  console.log(`   Pass: ${testAccount.pass}`);

  return nodemailer.createTransport({
    host: 'smtp.ethereal.email',
    port: 587,
    secure: false,
    auth: {
      user: testAccount.user,
      pass: testAccount.pass,
    },
  });
};

/**
 * Sends an OTP email to the given address.
 * @param {string} toEmail - Recipient email
 * @param {string} otp - The OTP code
 * @param {string} purpose - 'signup' | 'login'
 * @returns {Promise<string|null>} Preview URL (Ethereal only) or null
 */
const sendOtpEmail = async (toEmail, otp, purpose = 'login') => {
  const transporter = await createTransporter();

  const isSignup = purpose === 'signup';
  const subject = isSignup
    ? 'Welcome to FreshCart — Verify your Email'
    : 'Your FreshCart Login OTP';

  const htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0;padding:0;background-color:#f3f4f6;font-family:'Segoe UI',Roboto,Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f3f4f6;padding:40px 20px;">
    <tr>
      <td align="center">
        <table width="100%" style="max-width:520px;background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.07);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg,#10B981,#059669);padding:36px 40px;text-align:center;">
              <div style="font-size:36px;margin-bottom:8px;">🛒</div>
              <h1 style="margin:0;color:#ffffff;font-size:22px;font-weight:700;letter-spacing:-0.5px;">FreshCart</h1>
              <p style="margin:4px 0 0;color:#A7F3D0;font-size:13px;">Fresh Groceries Delivered</p>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px;">
              <h2 style="margin:0 0 8px;color:#1F2937;font-size:20px;font-weight:700;">
                ${isSignup ? 'Verify your email address' : 'Login verification code'}
              </h2>
              <p style="margin:0 0 24px;color:#6B7280;font-size:14px;line-height:1.6;">
                ${
                  isSignup
                    ? 'Thank you for signing up! Use the code below to complete your registration.'
                    : 'Enter this code to securely log in to your account. It expires in 5 minutes.'
                }
              </p>

              <!-- OTP Box -->
              <div style="background:#ECFDF5;border:2px solid #A7F3D0;border-radius:12px;padding:28px;text-align:center;margin-bottom:24px;">
                <p style="margin:0 0 8px;color:#065F46;font-size:13px;font-weight:600;letter-spacing:1px;text-transform:uppercase;">Your One-Time Password</p>
                <div style="font-size:42px;font-weight:800;letter-spacing:12px;color:#10B981;font-family:'Courier New',monospace;">${otp}</div>
                <p style="margin:12px 0 0;color:#6B7280;font-size:12px;">⏱ Expires in 5 minutes</p>
              </div>

              <p style="margin:0;color:#9CA3AF;font-size:12px;line-height:1.6;">
                If you did not request this code, you can safely ignore this email. Your account remains secure.
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background:#F9FAFB;padding:20px 40px;border-top:1px solid #F3F4F6;text-align:center;">
              <p style="margin:0;color:#D1D5DB;font-size:11px;">© ${new Date().getFullYear()} FreshCart. All rights reserved.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

  const mailOptions = {
    from: `"FreshCart 🛒" <${process.env.SMTP_FROM || process.env.SMTP_USER || 'noreply@freshcart.app'}>`,
    to: toEmail,
    subject,
    html: htmlBody,
    text: `Your FreshCart OTP is: ${otp}. It expires in 5 minutes.`,
  };

  const info = await transporter.sendMail(mailOptions);

  console.log('==========================================');
  console.log(`📧 [Email OTP] Sent to: ${toEmail}`);
  console.log(`   OTP Code : ${otp}`);
  console.log(`   Message ID: ${info.messageId}`);

  // Ethereal preview URL (only available when using Ethereal test accounts)
  const previewUrl = nodemailer.getTestMessageUrl(info);
  if (previewUrl) {
    console.log(`   Preview URL: ${previewUrl}`);
  }
  console.log('==========================================');

  return previewUrl || null;
};

module.exports = {
  generateOtp,
  sendOtpEmail,
};
