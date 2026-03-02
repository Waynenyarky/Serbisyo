const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const oauthProviderSchema = new mongoose.Schema({
  id: { type: String },
  email: { type: String },
  linkedAt: { type: Date },
}, { _id: false });

const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String },
  fullName: { type: String, required: true },
  is_customer: { type: Boolean, default: true },
  is_provider: { type: Boolean, default: false },
  is_admin: { type: Boolean, default: false },
  admin_role: { type: String, default: null },
  oauthProviders: {
    google: { type: oauthProviderSchema, default: null },
  },
}, { timestamps: true });

userSchema.pre('save', async function (next) {
  if (!this.password && !this.oauthProviders?.google?.id) {
    return next(new Error('Password or OAuth provider is required'));
  }
  if (!this.isModified('password')) return next();
  if (!this.password) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

userSchema.methods.comparePassword = function (candidate) {
  if (!this.password) return false;
  return bcrypt.compare(candidate, this.password);
};

userSchema.set('toJSON', {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    ret.role = ret.is_admin ? 'admin' : (ret.is_provider ? 'provider' : 'customer');
    delete ret._id;
    delete ret.__v;
    delete ret.password;
    if (ret.oauthProviders?.google?.id) {
      ret.oauthProviders.google = {
        email: ret.oauthProviders.google.email,
        linkedAt: ret.oauthProviders.google.linkedAt,
      };
    }
    return ret;
  },
});

module.exports = mongoose.model('User', userSchema);
