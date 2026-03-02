require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');
const ServiceCategory = require('./models/ServiceCategory');
const Service = require('./models/Service');
const { connectDB } = require('./config/db');

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

const schemaCollections = ['payments', 'reviews', 'messages', 'adminlogs'];

async function ensureSchemaCollections() {
  const existing = await mongoose.connection.db.listCollections().toArray();
  const existingNames = new Set(existing.map((item) => item.name));
  for (const collectionName of schemaCollections) {
    if (!existingNames.has(collectionName)) {
      await mongoose.connection.createCollection(collectionName);
    }
  }
}

async function backfillUsersSchemaFields() {
  const usersCollection = mongoose.connection.collection('users');
  const users = await usersCollection.find({}).toArray();
  if (!users.length) return;

  const ops = users.map((user) => {
    const hasAddress = user.address && typeof user.address === 'object';
    return {
      updateOne: {
        filter: { _id: user._id },
        update: {
          $set: {
            name: user.name || user.fullName || user.email,
            password_hash: user.password_hash || user.password || null,
            phone: user.phone || '',
            address: hasAddress ? user.address : {
              street: '',
              city: '',
              province: '',
              coordinates: [0, 0],
            },
            profile_picture: user.profile_picture || null,
            ratings: typeof user.ratings === 'number' ? user.ratings : 0,
            created_at: user.created_at || user.createdAt || new Date(),
            updated_at: user.updated_at || user.updatedAt || new Date(),
            admin_role: user.admin_role ?? null,
            is_customer: !!user.is_customer,
            is_provider: !!user.is_provider,
            is_admin: !!user.is_admin,
          },
        },
      },
    };
  });

  await usersCollection.bulkWrite(ops, { ordered: false });
}

async function backfillServicesSchemaFields() {
  const servicesCollection = mongoose.connection.collection('services');
  const categories = await ServiceCategory.find({}).lean();
  const categoryNameById = new Map(categories.map((category) => [category._id.toString(), category.name]));

  const servicesDocs = await servicesCollection.find({}).toArray();
  if (!servicesDocs.length) return;

  const ops = servicesDocs.map((serviceDoc) => ({
    updateOne: {
      filter: { _id: serviceDoc._id },
      update: {
        $set: {
          name: serviceDoc.name || serviceDoc.title,
          category: serviceDoc.category || categoryNameById.get(serviceDoc.categoryId?.toString?.()) || null,
          base_price: Number(serviceDoc.base_price ?? serviceDoc.pricePerHour ?? 0),
          created_at: serviceDoc.created_at || serviceDoc.createdAt || new Date(),
          updated_at: serviceDoc.updated_at || serviceDoc.updatedAt || new Date(),
        },
      },
    },
  }));

  await servicesCollection.bulkWrite(ops, { ordered: false });
}

async function seed() {
  await connectDB();
  await ensureSchemaCollections();

  // Ensure boolean role flags exist for all users.
  await User.updateMany(
    { is_customer: { $exists: false } },
    { $set: { is_customer: true } }
  );
  await User.updateMany(
    { is_provider: { $exists: false } },
    { $set: { is_provider: false } }
  );
  await User.updateMany(
    { is_admin: { $exists: false } },
    { $set: { is_admin: false } }
  );

  // Legacy migration: map old roleId/provider role documents to is_provider=true.
  const providerRole = await mongoose.connection.collection('roles').findOne({ slug: 'provider' });
  if (providerRole?._id) {
    await mongoose.connection.collection('users').updateMany(
      { roleId: providerRole._id },
      { $set: { is_provider: true, is_customer: true } }
    );
  }

  await ServiceCategory.deleteMany({});
  await Service.deleteMany({});
  const inserted = await ServiceCategory.insertMany(categories);
  const catMap = {};
  inserted.forEach(c => { catMap[c.name] = c._id; });

  const providerIdsByEmail = {};
  for (const h of hosts) {
    let user = await User.findOne({ email: h.email.toLowerCase() });
    if (!user) {
      user = await User.create({
        email: h.email.toLowerCase(),
        password: h.password,
        fullName: h.fullName,
        is_customer: true,
        is_provider: true,
      });
    } else if (!user.is_provider) {
      user.is_provider = true;
      user.is_customer = true;
      await user.save();
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
  await backfillUsersSchemaFields();
  await backfillServicesSchemaFields();
  console.log('Seeded categories and services. Bookers can see and book these host offerings.');
  process.exit(0);
}

seed().catch(err => { console.error(err); process.exit(1); });
