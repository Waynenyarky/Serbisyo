require('dotenv').config();
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
  { email: 'host.miguel.reyes@serbisyo.demo', password: 'demo1234', fullName: 'Miguel Reyes', providerName: 'PrimeFlow Plumbing' },
  { email: 'host.lianne.cruz@serbisyo.demo', password: 'demo1234', fullName: 'Lianne Cruz', providerName: 'UrbanSprout Gardens' },
  { email: 'host.paolo.garcia@serbisyo.demo', password: 'demo1234', fullName: 'Paolo Garcia', providerName: 'BrightNest Cleaning' },
  { email: 'host.jerome.tan@serbisyo.demo', password: 'demo1234', fullName: 'Jerome Tan', providerName: 'QuickMend Home Repair' },
  { email: 'host.rafael.mendoza@serbisyo.demo', password: 'demo1234', fullName: 'Rafael Mendoza', providerName: 'VoltGuard Electrical' },
  { email: 'host.kevin.delacruz@serbisyo.demo', password: 'demo1234', fullName: 'Kevin Dela Cruz', providerName: 'LiftLine Movers' },
  { email: 'host.sofia.bautista@serbisyo.demo', password: 'demo1234', fullName: 'Sofia Bautista', providerName: 'PetCare Buddy PH' },
  { email: 'host.camille.navarro@serbisyo.demo', password: 'demo1234', fullName: 'Camille Navarro', providerName: 'Tranquil Touch Wellness' },
  { email: 'host.noel.flores@serbisyo.demo', password: 'demo1234', fullName: 'Noel Flores', providerName: 'AquaShield Plumbing' },
  { email: 'host.angela.perez@serbisyo.demo', password: 'demo1234', fullName: 'Angela Perez', providerName: 'LeafLine Garden Services' },
  { email: 'host.vincent.ramos@serbisyo.demo', password: 'demo1234', fullName: 'Vincent Ramos', providerName: 'MetroFix Appliance Care' },
  { email: 'host.bianca.lopez@serbisyo.demo', password: 'demo1234', fullName: 'Bianca Lopez', providerName: 'GlowHome Wellness' },
];

async function seedHosts() {
  await connectDB();

  const created = [];
  const existing = [];
  for (const h of hosts) {
    const user = await User.findOne({ email: h.email.toLowerCase() });
    if (user) {
      if (!user.is_provider) {
        user.is_provider = true;
        user.is_customer = true;
        await user.save();
      }
      existing.push(h.email);
      continue;
    }
    await User.create({
      email: h.email.toLowerCase(),
      password: h.password,
      fullName: h.fullName,
      is_customer: true,
      is_provider: true,
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
