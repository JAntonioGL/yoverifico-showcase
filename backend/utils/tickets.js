// utils/tickets.js
const jwt = require('jsonwebtoken');

const TICKET_AUD = process.env.SIGNUP_TICKET_AUDIENCE || 'yoverifico-signup';
const TICKET_ISS = process.env.SIGNUP_TICKET_ISSUER   || 'yoverifico';

function verifySignupTicket(token) {
  return jwt.verify(token, process.env.JWT_SECRET, {
    audience:  TICKET_AUD,
    issuer:    TICKET_ISS,
    algorithms: ['HS256'],
  });
}

module.exports = { verifySignupTicket };
