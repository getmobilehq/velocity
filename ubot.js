#Whatsapp Bot CRM
require('dotenv').config();
const { create } = require('@openwa/wa-automate');
const axios = require('axios');

const API_URL = process.env.API_URL;

create().then(client => start(client));

async function start(client) {
  client.onMessage(async message => {
    try {
      const phone = message.from;
      const trigger = message.body.toUpperCase();
      
      const { data } = await axios.get(`${API_URL}?phone=${phone}&trigger=${trigger}`);
      if (!data.message) return;
      
      const response = formatResponse(data);
      await client.sendText(phone, response);
      
      await axios.post(API_URL, {
        phone,
        message: trigger,
        direction: 'received',
        status: data.next_status,
        decision: data.next_decision,
        course_id: getCourseId(trigger)
      });
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });

  setInterval(handleFollowUps, 60000, client);
}

function formatResponse(data) {
  return data.message
    .replace('[FULLNAME]', data.fullname || '')
    .replace('[Course Name]', data.course_name || 'the course')
    .replace('[Start Date]', data.start_date || 'soon')
    .replace('[Payment Link]', data.payment_link || '')
    .replace('[Access Link]', data.access_link || '');
}

async function handleFollowUps(client) {
  try {
    const { data: followups } = await axios.get(`${API_URL}/followups`);
    for (const followup of followups) {
      const response = formatResponse(followup);
      await client.sendText(followup.phone, response);
      await axios.post(API_URL, {
        phone: followup.phone,
        message: 'FOLLOWUP',
        direction: 'sent'
      });
    }
  } catch (error) {
    console.error('Error handling follow-ups:', error);
  }
}

function getCourseId(trigger) {
  const courseMap = {
    'COURSE1': 1,
    'COURSE2': 2
  };
  return courseMap[trigger];
}
