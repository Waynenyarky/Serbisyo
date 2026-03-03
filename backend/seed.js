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
  {
    title: 'Drain Cleaning & Leak Fix',
    categoryName: 'Plumbing',
    rating: 4.7,
    reviewCount: 98,
    pricePerHour: 360,
    providerName: 'PrimeFlow Plumbing',
    description: 'Quick drain cleaning and leak repair for homes and condos.',
    offers: 'Kitchen and bathroom drain declogging\nLeak tracing and sealing\nBasic pipe pressure check',
    locationDescription: 'Serving Quezon City, San Juan, and nearby Metro Manila areas.',
    availability: 'Mon–Sun, 8:00 AM – 7:00 PM',
    thingsToKnow: 'Client provides access to water line shutoff.\nReplacement parts are billed separately.\nPlease keep work area clear before arrival.',
  },
  {
    title: 'Condo Balcony Garden Care',
    categoryName: 'Gardening',
    rating: 4.8,
    reviewCount: 74,
    pricePerHour: 300,
    providerName: 'UrbanSprout Gardens',
    description: 'Routine balcony and pocket-garden maintenance.',
    offers: 'Plant pruning and shaping\nSoil top-up and light fertilizing\nPest spot treatment for common issues',
    locationDescription: 'Ideal for condo balconies and small urban gardens in Metro Manila.',
    availability: 'Tue–Sun, 7:00 AM – 4:00 PM',
    thingsToKnow: 'Please provide access to water source.\nFertilizer upgrades are optional.\nService is for non-tree plants only.',
  },
  {
    title: 'Post-Renovation Cleaning',
    categoryName: 'Housekeeping',
    rating: 4.9,
    reviewCount: 121,
    pricePerHour: 480,
    providerName: 'BrightNest Cleaning',
    description: 'Detailed cleanup after renovations or repainting.',
    offers: 'Dust and debris removal\nSurface wipe-down and sanitizing\nFloor and bathroom deep clean',
    locationDescription: 'Available for condos, apartments, and townhouses across Metro Manila.',
    availability: 'Mon–Sat, 9:00 AM – 7:00 PM',
    thingsToKnow: 'Heavy construction debris is excluded.\nClient secures elevator booking if needed.\nParking fees are billed to client.',
  },
  {
    title: 'Aircon & Small Appliance Repair',
    categoryName: 'Repairs',
    rating: 4.6,
    reviewCount: 83,
    pricePerHour: 420,
    providerName: 'QuickMend Home Repair',
    description: 'Diagnostics and repair for aircon units and home appliances.',
    offers: 'Initial diagnostics and fault isolation\nMinor repairs and part replacement\nFunction and safety verification',
    locationDescription: 'On-site visits within Manila, Makati, and nearby cities.',
    availability: 'Mon–Fri, 10:00 AM – 6:00 PM',
    thingsToKnow: 'Diagnostic fee is non-refundable.\nParts are quoted separately before install.\nBring model/serial details for faster checks.',
  },
  {
    title: 'Circuit Breaker Troubleshooting',
    categoryName: 'Electrical',
    rating: 4.8,
    reviewCount: 69,
    pricePerHour: 390,
    providerName: 'VoltGuard Electrical',
    description: 'Safe troubleshooting for tripping breakers and power fluctuations.',
    offers: 'Panel and breaker inspection\nLoad balancing checks\nOutlet and switch testing',
    locationDescription: 'Metro Manila residential and small office service coverage.',
    availability: 'Mon–Sat, 8:00 AM – 5:00 PM',
    thingsToKnow: 'Temporary shutdown may be required.\nMajor rewiring requires separate quotation.\nBuilding permits remain client responsibility.',
  },
  {
    title: 'Condo Move-In Assistance',
    categoryName: 'Moving',
    rating: 4.7,
    reviewCount: 110,
    pricePerHour: 340,
    providerName: 'LiftLine Movers',
    description: 'Efficient moving help tailored for condo move-ins.',
    offers: 'Loading and unloading support\nBasic furniture assembly\nProtective wrapping for appliances',
    locationDescription: 'Serving major Metro Manila condo districts.',
    availability: 'Mon–Sun, 7:00 AM – 8:00 PM',
    thingsToKnow: 'Client arranges building permits/schedule.\nTolls and parking are charged separately.\nAdditional manpower available by request.',
  },
  {
    title: 'Cat Sitting & Feeding Visit',
    categoryName: 'Pet Care',
    rating: 4.9,
    reviewCount: 88,
    pricePerHour: 220,
    providerName: 'PetCare Buddy PH',
    description: 'Home visits for cat feeding, litter cleaning, and playtime.',
    offers: 'Feeding and fresh water refill\nLitter box cleaning\nPhoto and activity updates',
    locationDescription: 'Available in Makati, Pasig, Taguig, and nearby areas.',
    availability: 'Mon–Sun, 8:00 AM – 9:00 PM',
    thingsToKnow: 'Please provide feeding instructions.\nAggressive pets require prior briefing.\nEmergency vet contact must be shared.',
  },
  {
    title: 'In-Home Ventosa Massage',
    categoryName: 'Beauty & Wellness',
    rating: 4.8,
    reviewCount: 95,
    pricePerHour: 550,
    providerName: 'Tranquil Touch Wellness',
    description: 'Traditional ventosa and relaxation therapy at home.',
    offers: 'Ventosa cupping therapy\nBack and shoulder relaxation massage\nAromatherapy oils included',
    locationDescription: 'In-home service for Metro Manila residences.',
    availability: 'Mon–Sun, 12:00 PM – 10:00 PM',
    thingsToKnow: 'Not recommended for certain skin conditions.\nShare medical concerns before session.\nLate cancellations may incur fees.',
  },
  {
    title: 'Bathroom Fixture Installation',
    categoryName: 'Plumbing',
    rating: 4.7,
    reviewCount: 64,
    pricePerHour: 370,
    providerName: 'AquaShield Plumbing',
    description: 'Installation and replacement of bathroom plumbing fixtures.',
    offers: 'Faucet and shower set installation\nToilet flush mechanism replacement\nLeak and seal checks',
    locationDescription: 'Service available across central and south Metro Manila.',
    availability: 'Mon–Sat, 9:00 AM – 6:00 PM',
    thingsToKnow: 'Client supplies preferred fixtures.\nUnexpected pipe issues may need additional work.\nPlease ensure water access during install.',
  },
  {
    title: 'Plant Repotting & Soil Refresh',
    categoryName: 'Gardening',
    rating: 4.8,
    reviewCount: 57,
    pricePerHour: 290,
    providerName: 'LeafLine Garden Services',
    description: 'Repotting and soil care for indoor and outdoor plants.',
    offers: 'Repotting for small to medium plants\nSoil refresh and nutrient mix\nBasic plant health check',
    locationDescription: 'Best for condos and homes in Metro Manila.',
    availability: 'Tue–Sun, 8:00 AM – 5:00 PM',
    thingsToKnow: 'Pots and premium soil can be client-provided.\nTree-sized plants are excluded.\nKindly prepare a working area.',
  },
  {
    title: 'Washing Machine Repair',
    categoryName: 'Repairs',
    rating: 4.6,
    reviewCount: 72,
    pricePerHour: 410,
    providerName: 'MetroFix Appliance Care',
    description: 'Troubleshooting and repair for automatic and semi-auto washers.',
    offers: 'Error code diagnostics\nDrain and spin issue repair\nOperational safety check',
    locationDescription: 'Home service in Quezon City, Manila, and nearby cities.',
    availability: 'Mon–Fri, 9:00 AM – 6:00 PM',
    thingsToKnow: 'Diagnostic fee applies per visit.\nParts availability may affect turnaround.\nPlease share model and issue details in advance.',
  },
  {
    title: 'Prenatal Home Massage',
    categoryName: 'Beauty & Wellness',
    rating: 4.9,
    reviewCount: 61,
    pricePerHour: 520,
    providerName: 'GlowHome Wellness',
    description: 'Gentle home massage sessions for prenatal relaxation.',
    offers: 'Prenatal-safe massage techniques\nLower back and leg relief focus\nClean linens and hypoallergenic oil',
    locationDescription: 'Available for home bookings within Metro Manila.',
    availability: 'Mon–Sun, 10:00 AM – 8:00 PM',
    thingsToKnow: 'Medical clearance may be required.\nPlease disclose pregnancy stage and conditions.\nQuiet, ventilated space is recommended.',
  },
];

// Host (provider) users for bookers to see services from. Each has distinct services.
const hosts = [
  { email: 'provider@serbisyo.demo', password: 'demo1234', fullName: 'Demo Provider', providerName: 'Juan Plumbing', serviceIndexes: [0], coordinates: [121.0244, 14.5547] },
  { email: 'host.green@serbisyo.demo', password: 'demo1234', fullName: 'Maria Santos', providerName: 'Green Thumb Co', serviceIndexes: [1], coordinates: [121.0338, 14.5657] },
  { email: 'host.sparkle@serbisyo.demo', password: 'demo1234', fullName: 'Ana Reyes', providerName: 'Sparkle Clean', serviceIndexes: [2], coordinates: [121.0437, 14.5764] },
  { email: 'host.fixit@serbisyo.demo', password: 'demo1234', fullName: 'Carlos Fix-It', providerName: 'Fix-It Pro', serviceIndexes: [3], coordinates: [121.0194, 14.5428] },
  { email: 'host.electric@serbisyo.demo', password: 'demo1234', fullName: 'SafeWire Electric', providerName: 'SafeWire Electric', serviceIndexes: [4], coordinates: [121.0059, 14.5848] },
  { email: 'host.move@serbisyo.demo', password: 'demo1234', fullName: 'Move It Co', providerName: 'Move It Co', serviceIndexes: [5], coordinates: [120.9980, 14.5560] },
  { email: 'host.paw@serbisyo.demo', password: 'demo1234', fullName: 'Paw Friends', providerName: 'Paw Friends', serviceIndexes: [6], coordinates: [121.0568, 14.5514] },
  { email: 'host.serenity@serbisyo.demo', password: 'demo1234', fullName: 'Serenity Spa', providerName: 'Serenity Spa', serviceIndexes: [7], coordinates: [121.0415, 14.5347] },
  { email: 'host.miguel.reyes@serbisyo.demo', password: 'demo1234', fullName: 'Miguel Reyes', providerName: 'PrimeFlow Plumbing', serviceIndexes: [8], coordinates: [121.0370, 14.6760] },
  { email: 'host.lianne.cruz@serbisyo.demo', password: 'demo1234', fullName: 'Lianne Cruz', providerName: 'UrbanSprout Gardens', serviceIndexes: [9], coordinates: [121.0810, 14.6210] },
  { email: 'host.paolo.garcia@serbisyo.demo', password: 'demo1234', fullName: 'Paolo Garcia', providerName: 'BrightNest Cleaning', serviceIndexes: [10], coordinates: [121.0512, 14.5896] },
  { email: 'host.jerome.tan@serbisyo.demo', password: 'demo1234', fullName: 'Jerome Tan', providerName: 'QuickMend Home Repair', serviceIndexes: [11], coordinates: [121.0176, 14.6042] },
  { email: 'host.rafael.mendoza@serbisyo.demo', password: 'demo1234', fullName: 'Rafael Mendoza', providerName: 'VoltGuard Electrical', serviceIndexes: [12], coordinates: [121.0445, 14.5542] },
  { email: 'host.kevin.delacruz@serbisyo.demo', password: 'demo1234', fullName: 'Kevin Dela Cruz', providerName: 'LiftLine Movers', serviceIndexes: [13], coordinates: [121.0467, 14.5204] },
  { email: 'host.sofia.bautista@serbisyo.demo', password: 'demo1234', fullName: 'Sofia Bautista', providerName: 'PetCare Buddy PH', serviceIndexes: [14], coordinates: [121.0942, 14.5764] },
  { email: 'host.camille.navarro@serbisyo.demo', password: 'demo1234', fullName: 'Camille Navarro', providerName: 'Tranquil Touch Wellness', serviceIndexes: [15], coordinates: [120.9946, 14.5311] },
  { email: 'host.noel.flores@serbisyo.demo', password: 'demo1234', fullName: 'Noel Flores', providerName: 'AquaShield Plumbing', serviceIndexes: [16], coordinates: [121.0031, 14.6507] },
  { email: 'host.angela.perez@serbisyo.demo', password: 'demo1234', fullName: 'Angela Perez', providerName: 'LeafLine Garden Services', serviceIndexes: [17], coordinates: [121.1175, 14.5832] },
  { email: 'host.vincent.ramos@serbisyo.demo', password: 'demo1234', fullName: 'Vincent Ramos', providerName: 'MetroFix Appliance Care', serviceIndexes: [18], coordinates: [121.0265, 14.4506] },
  { email: 'host.bianca.lopez@serbisyo.demo', password: 'demo1234', fullName: 'Bianca Lopez', providerName: 'GlowHome Wellness', serviceIndexes: [19], coordinates: [121.0028, 14.4850] },
];

const schemaCollections = ['payments', 'reviews', 'messages', 'adminlogs'];

function normalizeGeoPoint(value) {
  if (Array.isArray(value) && value.length === 2 && value.every(Number.isFinite)) {
    return { type: 'Point', coordinates: value };
  }
  if (
    value
    && typeof value === 'object'
    && value.type === 'Point'
    && Array.isArray(value.coordinates)
    && value.coordinates.length === 2
    && value.coordinates.every(Number.isFinite)
  ) {
    return { type: 'Point', coordinates: value.coordinates };
  }
  return { type: 'Point', coordinates: [0, 0] };
}

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
    const normalizedAddress = hasAddress ? {
      ...user.address,
      coordinates: normalizeGeoPoint(user.address.coordinates),
    } : {
      street: '',
      city: '',
      province: '',
      coordinates: { type: 'Point', coordinates: [0, 0] },
    };
    return {
      updateOne: {
        filter: { _id: user._id },
        update: {
          $set: {
            name: user.name || user.fullName || user.email,
            password_hash: user.password_hash || user.password || null,
            phone: user.phone || '',
            address: normalizedAddress,
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
        address: {
          coordinates: {
            type: 'Point',
            coordinates: h.coordinates || [0, 0],
          },
        },
      });
    } else {
      if (!user.is_provider) {
        user.is_provider = true;
        user.is_customer = true;
      }
      const currentCoordinates = user.address?.coordinates;
      const normalized = normalizeGeoPoint(currentCoordinates);
      const hasZeroCoordinates = normalized.coordinates[0] === 0 && normalized.coordinates[1] === 0;
      if (hasZeroCoordinates) {
        user.address = {
          ...(user.address || {}),
          coordinates: {
            type: 'Point',
            coordinates: h.coordinates || [0, 0],
          },
        };
      }
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
