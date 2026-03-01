require('dotenv').config();
const Role = require('./models/Role');
const User = require('./models/User');
const { connectDB } = require('./config/db');

/**
 * Host (provider) accounts for Serbisyo.
 * Run: npm run seed:hosts
 * Use these to log in as a host in the app (e.g. provider@serbisyo.demo / demo1234).
 */
const hosts = [
  { email: 'provider@serbisyo.demo', password: 'demo1234', fullName: 'Demo Provider', providerName: 'Juan Plumbing' },
  { email: 'host.green@serbisyo.demo', password: 'demo1234', fullName: 'Maria Santos', providerName: 'Green Thumb Co' },
  { email: 'host.sparkle@serbisyo.demo', password: 'demo1234', fullName: 'Ana Reyes', providerName: 'Sparkle Clean' },
  { email: 'host.fixit@serbisyo.demo', password: 'demo1234', fullName: 'Carlos Fix-It', providerName: 'Fix-It Pro' },
  { email: 'host.electric@serbisyo.demo', password: 'demo1234', fullName: 'SafeWire Electric', providerName: 'SafeWire Electric' },
  { email: 'host.move@serbisyo.demo', password: 'demo1234', fullName: 'Move It Co', providerName: 'Move It Co' },
  { email: 'host.paw@serbisyo.demo', password: 'demo1234', fullName: 'Paw Friends', providerName: 'Paw Friends' },
  { email: 'host.serenity@serbisyo.demo', password: 'demo1234', fullName: 'Serenity Spa', providerName: 'Serenity Spa' },
];

async function seedHosts() {
  await connectDB();

  let providerRole = await Role.findOne({ slug: 'provider' });
  if (!providerRole) {
    providerRole = await Role.create({ name: 'Provider', slug: 'provider' });
    console.log('Created provider role.');
  }

  const created = [];
  const existing = [];
  for (const h of hosts) {
    const user = await User.findOne({ email: h.email });
    if (user) {
      existing.push(h.email);
      continue;
    }
    await User.create({
      email: h.email,
      password: h.password,
      fullName: h.fullName,
      roleId: providerRole._id,
    });
    created.push(h.email);
  }

  console.log('Host accounts seeded.');
  if (created.length) console.log('Created:', created.join(', '));
  if (existing.length) console.log('Already existed:', existing.join(', '));
  console.log('Total host accounts:', hosts.length);
  process.exit(0);
}

seedHosts().catch(err => {
  console.error(err);
  process.exit(1);
});
