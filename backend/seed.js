require('dotenv').config();
const mongoose = require('mongoose');
const Role = require('./models/Role');
const User = require('./models/User');
const ServiceCategory = require('./models/ServiceCategory');
const Service = require('./models/Service');
const { connectDB } = require('./config/db');

const roles = [
  { name: 'Customer', slug: 'customer' },
  { name: 'Provider', slug: 'provider' },
  { name: 'Admin', slug: 'admin' },
];

const categories = [
  { name: 'Plumbing', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Gardening', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Housekeeping', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Repairs', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Electrical', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Moving', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Pet Care', assetImagePath: 'assets/images/placeholders/placeholder.png' },
  { name: 'Beauty & Wellness', assetImagePath: 'assets/images/placeholders/placeholder.png' },
];

const services = [
  {
    title: 'Emergency Plumbing',
    categoryName: 'Plumbing',
    rating: 4.8,
    reviewCount: 124,
    pricePerHour: 350,
    providerName: 'Juan Plumbing',
    description: 'Fast and reliable plumbing repairs.',
    offers: '24/7 emergency leak repair\nPipe replacement and unclogging\nInspection of visible plumbing lines',
    locationDescription: 'Service available across Metro Manila. Technician visits your home or business.',
    availability: 'Mon–Sun, 8:00 AM – 8:00 PM',
    thingsToKnow: 'Please ensure someone 18+ is present during the visit.\nParking space for service vehicle is required.\nAdditional parts are billed separately.',
  },
  {
    title: 'Garden Maintenance',
    categoryName: 'Gardening',
    rating: 4.9,
    reviewCount: 89,
    pricePerHour: 280,
    providerName: 'Green Thumb Co',
    description: 'Lawn care and garden upkeep.',
    offers: 'Lawn mowing and edging\nShrub trimming and basic landscaping\nGreen waste bagging and disposal',
    locationDescription: 'Available for houses and townhouses with small to medium gardens.',
    availability: 'Tue–Sun, 7:00 AM – 5:00 PM',
    thingsToKnow: 'Access to an outdoor water source is required.\nKindly secure pets before the visit.\nHeavy landscaping is quoted separately.',
  },
  {
    title: 'Full House Cleaning',
    categoryName: 'Housekeeping',
    rating: 4.7,
    reviewCount: 256,
    pricePerHour: 450,
    providerName: 'Sparkle Clean',
    description: 'Deep cleaning for your home.',
    offers: 'Deep cleaning of bedrooms, living areas, and kitchen\nBathroom descaling and disinfecting\nBasic interior window cleaning',
    locationDescription: 'Ideal for condos and homes up to 3 bedrooms.',
    availability: 'Mon–Sat, 9:00 AM – 6:00 PM',
    thingsToKnow: 'Please declutter valuable items before the team arrives.\nClient provides access to electricity and running water.\nParking or condo fees are shouldered by the client.',
  },
  {
    title: 'Appliance Repair',
    categoryName: 'Repairs',
    rating: 4.6,
    reviewCount: 67,
    pricePerHour: 400,
    providerName: 'Fix-It Pro',
    description: 'Repair and maintenance for appliances.',
    offers: 'Diagnostics for common home appliances\nMinor repairs and part replacement (if available)\nSafety checks after every repair',
    locationDescription: 'On-site service within Metro Manila and nearby cities.',
    availability: 'Mon–Fri, 10:00 AM – 7:00 PM',
    thingsToKnow: 'Booking fee covers diagnostics only.\nParts are quoted and approved before installation.\nOld parts can be left with the client upon request.',
  },
  {
    title: 'Wiring & Install',
    categoryName: 'Electrical',
    rating: 4.7,
    reviewCount: 92,
    pricePerHour: 380,
    providerName: 'SafeWire Electric',
    description: 'Licensed electrical work and installations.',
    offers: 'Installation of outlets, lights, and switches\nInspection of existing electrical lines\nMinor troubleshooting for power issues',
    locationDescription: 'Servicing condos, apartments, and houses within service radius.',
    availability: 'Mon–Sat, 9:00 AM – 5:00 PM',
    thingsToKnow: 'Power interruptions may be required during work.\nFor major rewiring, a separate quotation is provided.\nClient must secure building permits if needed.',
  },
  {
    title: 'Furniture Moving',
    categoryName: 'Moving',
    rating: 4.5,
    reviewCount: 156,
    pricePerHour: 320,
    providerName: 'Move It Co',
    description: 'Local moving and heavy lifting.',
    offers: 'Loading and unloading of furniture\nBasic furniture disassembly and assembly\nProtective wrapping for large items',
    locationDescription: 'Metro Manila and nearby cities, origin or destination.',
    availability: 'Mon–Sun, 7:00 AM – 7:00 PM',
    thingsToKnow: 'Client confirms building move-in/move-out rules.\nExtra helpers can be arranged with prior notice.\nTolls and parking are billed to the client.',
  },
  {
    title: 'Dog Walking',
    categoryName: 'Pet Care',
    rating: 4.9,
    reviewCount: 203,
    pricePerHour: 200,
    providerName: 'Paw Friends',
    description: 'Dog walking and pet sitting.',
    offers: '30–60 minute walks tailored to your dog\nBasic feeding and water refill\nPhoto updates after each visit',
    locationDescription: 'Available in pet-friendly neighborhoods and condos.',
    availability: 'Mon–Sun, 6:00 AM – 8:00 PM',
    thingsToKnow: 'Dogs must be vaccinated and leashed.\nKindly prepare your dog’s harness, leash, and poop bags.\nAggressive pets may require a prior meet-and-greet.',
  },
  {
    title: 'Home Massage',
    categoryName: 'Beauty & Wellness',
    rating: 4.8,
    reviewCount: 178,
    pricePerHour: 500,
    providerName: 'Serenity Spa',
    description: 'Relaxing massage at your place.',
    offers: 'Swedish, deep tissue, and relaxation massage\nTherapist brings fresh linens and oils\nOptional add-ons like foot spa (additional fee)',
    locationDescription: 'In-home service for condos, apartments, and houses.',
    availability: 'Mon–Sun, 1:00 PM – 11:00 PM',
    thingsToKnow: 'A quiet, comfortable space is recommended.\nPlease inform the therapist of any health conditions.\nCancellations within 3 hours may incur a fee.',
  },
];

// Host (provider) users for bookers to see services from. Each has distinct services.
const hosts = [
  { email: 'provider@serbisyo.demo', password: 'demo1234', fullName: 'Demo Provider', providerName: 'Juan Plumbing', serviceIndexes: [0] },
  { email: 'host.green@serbisyo.demo', password: 'demo1234', fullName: 'Maria Santos', providerName: 'Green Thumb Co', serviceIndexes: [1] },
  { email: 'host.sparkle@serbisyo.demo', password: 'demo1234', fullName: 'Ana Reyes', providerName: 'Sparkle Clean', serviceIndexes: [2] },
  { email: 'host.fixit@serbisyo.demo', password: 'demo1234', fullName: 'Carlos Fix-It', providerName: 'Fix-It Pro', serviceIndexes: [3] },
  { email: 'host.electric@serbisyo.demo', password: 'demo1234', fullName: 'SafeWire Electric', providerName: 'SafeWire Electric', serviceIndexes: [4] },
  { email: 'host.move@serbisyo.demo', password: 'demo1234', fullName: 'Move It Co', providerName: 'Move It Co', serviceIndexes: [5] },
  { email: 'host.paw@serbisyo.demo', password: 'demo1234', fullName: 'Paw Friends', providerName: 'Paw Friends', serviceIndexes: [6] },
  { email: 'host.serenity@serbisyo.demo', password: 'demo1234', fullName: 'Serenity Spa', providerName: 'Serenity Spa', serviceIndexes: [7] },
];

async function seed() {
  await connectDB();

  // Seed roles (upsert by slug so we don't duplicate)
  for (const r of roles) {
    await Role.findOneAndUpdate({ slug: r.slug }, r, { upsert: true, new: true });
  }
  console.log('Seeded roles:', roles.map(r => r.slug).join(', '));

  // Migrate existing users without roleId to customer role
  const customerRole = await Role.findOne({ slug: 'customer' });
  if (customerRole) {
    const updated = await User.updateMany(
      { roleId: { $exists: false } },
      { $set: { roleId: customerRole._id } }
    );
    if (updated.modifiedCount > 0 || updated.matchedCount > 0) {
      console.log('Updated existing users with customer role:', updated.matchedCount);
    }
  }

  await ServiceCategory.deleteMany({});
  await Service.deleteMany({});
  const inserted = await ServiceCategory.insertMany(categories);
  const catMap = {};
  inserted.forEach(c => { catMap[c.name] = c._id; });

  const providerRole = await Role.findOne({ slug: 'provider' });
  if (!providerRole) {
    console.log('Provider role not found; skipping host/service seed.');
    process.exit(0);
    return;
  }

  const providerIdsByEmail = {};
  for (const h of hosts) {
    let user = await User.findOne({ email: h.email });
    if (!user) {
      user = await User.create({
        email: h.email,
        password: h.password,
        fullName: h.fullName,
        roleId: providerRole._id,
      });
    }
    providerIdsByEmail[h.email] = user._id;
  }
  console.log('Seeded host (provider) accounts:', hosts.length);

  const serviceDocs = services.map((s, idx) => {
    const host = hosts.find(h => h.serviceIndexes.includes(idx));
    const providerId = host ? providerIdsByEmail[host.email] : null;
    return {
      title: s.title,
      categoryId: catMap[s.categoryName],
      providerId: providerId || undefined,
      rating: s.rating,
      reviewCount: s.reviewCount,
      pricePerHour: s.pricePerHour,
      providerName: s.providerName,
      description: s.description,
      offers: s.offers,
      locationDescription: s.locationDescription,
      availability: s.availability,
      thingsToKnow: s.thingsToKnow,
      status: 'active',
    };
  });
  await Service.insertMany(serviceDocs);
  console.log('Seeded categories and services. Bookers can see and book these host offerings.');
  process.exit(0);
}

seed().catch(err => { console.error(err); process.exit(1); });
