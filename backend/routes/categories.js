const express = require('express');
const ServiceCategory = require('../models/ServiceCategory');

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const categories = await ServiceCategory.find().lean();
    const list = categories.map(c => ({
      id: c._id.toString(),
      name: c.name,
      assetImagePath: c.assetImagePath || 'assets/images/placeholders/placeholder.png',
    }));
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
