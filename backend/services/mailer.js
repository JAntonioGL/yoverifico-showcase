// services/mailer.js
const { EmailClient } = require("@azure/communication-email");

const FROM = (process.env.MAIL_FROM || 'DoNotReply@yoverifico.com.mx').trim();
const connectionString = process.env.AZURE_MAIL_CONNECTION_STRING;
const client = new EmailClient(connectionString);

/** Renderiza HTML completo con estructura estándar */
/** Renderiza HTML completo con estructura estándar */
function renderTemplate(template, { code, expiresMin, whenIso, ip, userAgent } = {}) {
  const exp = expiresMin ? `Expira en <b>${expiresMin}</b> minutos.` : '';
  let bodyContent = '';

  switch (template) {
    case 'signup':
      bodyContent = `
        <p style="font-size: 16px;">¡Hola!</p>
        <p>Gracias por unirte a <b>YoVerifico</b>. Tu código de verificación es:</p>
        <div style="background-color: #f4f7f9; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
          <h2 style="font-size: 32px; font-weight: bold; color: #2c3e50; margin: 0; letter-spacing: 5px;">${code}</h2>
        </div>
        <p style="font-size: 14px; color: #7f8c8d;">${exp} Si no solicitaste este código, puedes ignorar este correo de forma segura.</p>
      `;
      break;
    case 'pwd_reset':
      bodyContent = `
        <p>Recibimos una solicitud para <strong>restablecer tu contraseña</strong> en YoVerifico.</p>
        <p>Usa el siguiente código para continuar:</p>
        <div style="background-color: #f4f7f9; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
          <h2 style="font-size: 32px; font-weight: bold; color: #2c3e50; margin: 0; letter-spacing: 5px;">${code}</h2>
        </div>
        <p style="font-size: 14px; color: #7f8c8d;">${exp} Si no fuiste tú, te recomendamos cambiar tu contraseña y asegurar tu cuenta.</p>
      `;
      break;
    case 'pwd_changed_notice':
      bodyContent = `
        <p>Te informamos que la contraseña de tu cuenta ha sido <strong>actualizada exitosamente</strong>.</p>
        <div style="background-color: #fffaf0; border-left: 4px solid #f39c12; padding: 15px; margin: 20px 0;">
          <ul style="list-style: none; padding: 0; margin: 0; font-size: 13px; color: #555;">
            <li><b>Fecha (UTC):</b> ${whenIso || 'N/A'}</li>
            <li><b>Dirección IP:</b> ${ip || 'N/A'}</li>
          </ul>
        </div>
        <p>Si no realizaste este cambio, por favor recupera tu cuenta de inmediato o contacta a soporte.</p>
      `;
      break;
    default:
      bodyContent = `<p>Tu código de seguridad para YoVerifico es: <b style="font-size: 18px;">${code}</b></p>`;
  }

  return `
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>YoVerifico</title>
    </head>
    <body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; color: #333; line-height: 1.6; background-color: #f9f9f9; margin: 0; padding: 0;">
      <table width="100%" cellspacing="0" cellpadding="0" style="background-color: #f9f9f9; padding: 40px 0;">
        <tr>
          <td>
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 10px rgba(0,0,0,0.05); border: 1px solid #e1e1e1;">
              <div style="background-color: #2c3e50; padding: 20px; text-align: center;">
                <h1 style="color: #ffffff; margin: 0; font-size: 24px; letter-spacing: 1px;">YoVerifico</h1>
              </div>
              <div style="padding: 40px 30px;">
                ${bodyContent}
              </div>
              <div style="background-color: #f4f7f9; padding: 20px 30px; text-align: center; border-top: 1px solid #eee;">
                <p style="font-size: 12px; color: #7f8c8d; margin: 0 0 10px 0;">
                  Este es un mensaje automático, por favor no respondas directamente a este correo.
                </p>
                <p style="font-size: 13px; color: #34495e; margin: 0;">
                  ¿Tienes dudas o alguna aclaración? <br> 
                  Contáctanos en: <a href="mailto:soporte@yoverifico.com.mx" style="color: #3498db; text-decoration: none; font-weight: bold;">soporte@yoverifico.com.mx</a>
                </p>
              </div>
            </div>
          </td>
        </tr>
      </table>
    </body>
    </html>
  `;
}

/** Texto plano (Mantenlo simple para dispositivos básicos) */
function getPlainText(template, { code }) {
  const base = "\n\nEste es un mensaje automático. Cualquier aclaración, comentario o duda al siguiente correo: soporte@yoverifico.com.mx";
  switch (template) {
    case 'pwd_changed_notice':
      return `Tu contraseña de YoVerifico fue actualizada.${base}`;
    default:
      return `Tu código de YoVerifico es: ${code}.${base}`;
  }
}

/** Envío genérico de OTP con Azure */
async function sendOtpEmail(to, code, opts = {}) {
  const template = opts.template || 'signup';
  const expiresMin = Number(opts.expiresMin || 10);

  const subject =
    template === 'pwd_reset' ? 'YoVerifico · Código para restablecer contraseña' :
      template === 'account_delete' ? 'YoVerifico · Código para eliminar cuenta' :
        'YoVerifico · Código de verificación';

  const html = renderTemplate(template, { code, expiresMin });
  const plainText = getPlainText(template, { code });

  try {
    const message = {
      senderAddress: FROM,
      content: {
        subject: subject,
        html: html,
        plainText: plainText, // <--- Importante para SpamAssassin
      },
      recipients: {
        to: [{ address: to }],
      },
    };

    const poller = await client.beginSend(message);
    const result = await poller.pollUntilDone();

    return result.id;
  } catch (error) {
    console.error("Error en Azure Mailer:", error);
    throw new Error(`Error de envío: ${error.message}`);
  }
}

// Wrappers se mantienen igual...
async function sendSignupOtpEmail(to, code, { expiresMin = 10 } = {}) {
  return sendOtpEmail(to, code, { template: 'signup', expiresMin });
}
async function sendPwdResetOtpEmail(to, code, { expiresMin = 10 } = {}) {
  return sendOtpEmail(to, code, { template: 'pwd_reset', expiresMin });
}
async function sendAccountDeleteOtpEmail(to, code, { expiresMin = 10 } = {}) {
  return sendOtpEmail(to, code, { template: 'account_delete', expiresMin });
}

async function sendPasswordChangedEmail(to, { whenIso, ip, userAgent } = {}) {
  const html = renderTemplate('pwd_changed_notice', { whenIso, ip, userAgent });
  const plainText = getPlainText('pwd_changed_notice', {});

  try {
    const message = {
      senderAddress: FROM,
      content: {
        subject: 'YoVerifico · Tu contraseña fue actualizada',
        html: html,
        plainText: plainText,
      },
      recipients: { to: [{ address: to }] },
    };
    const poller = await client.beginSend(message);
    const result = await poller.pollUntilDone();
    return result.id;
  } catch (error) {
    throw new Error(`Azure Mail Error (Notice): ${error.message}`);
  }
}

module.exports = {
  sendOtpEmail,
  sendSignupOtpEmail,
  sendPwdResetOtpEmail,
  sendAccountDeleteOtpEmail,
  sendPasswordChangedEmail,
};