const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: 'gecpatanmess@gmail.com',
    pass: 'mzikqqadetrgjses'
  }
});

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method not allowed' });
  }

  try {
    const { email, otp } = req.body || {};
    if (!email || !otp) {
      return res.status(400).json({ success: false, error: 'Email and OTP are required' });
    }

    const mailOptions = {
      from: '"GEC Patan Hostel" <gecpatanmess@gmail.com>',
      to: email,
      subject: `GEC Patan Hostel - Your OTP: ${otp}`,
      text: `Hello,\n\nYour verification OTP for GEC Patan Hostel Mess is: ${otp}\n\nThis code is valid for 10 minutes. Please do not share it with anyone.\n\nRegards,\nGEC Patan Hostel Mess`
    };

    await transporter.sendMail(mailOptions);
    return res.status(200).json({ success: true, message: 'OTP sent successfully via Vercel SMTP' });

  } catch (error) {
    console.error('Vercel SMTP error:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
};
