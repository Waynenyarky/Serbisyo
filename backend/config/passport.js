const { Strategy: GoogleStrategy } = require('passport-google-oauth20');
const User = require('../models/User');

function configurePassport(passport) {
  const clientID = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  const callbackURL = process.env.GOOGLE_CALLBACK_URL || '/api/auth/oauth/google/callback';

  if (!clientID || !clientSecret) {
    return;
  }

  passport.use(new GoogleStrategy(
    {
      clientID,
      clientSecret,
      callbackURL,
      passReqToCallback: true,
    },
    async (req, accessToken, refreshToken, profile, done) => {
      try {
        const email = profile.emails?.[0]?.value?.toLowerCase?.() || null;
        const requestedRole = req.query.state === 'provider' ? 'provider' : 'customer';

        let user = await User.findOne({ 'oauthProviders.google.id': profile.id });
        if (!user && email) {
          user = await User.findOne({ email });
        }

        if (!user) {
          user = await User.create({
            email: email || `${profile.id}@google-oauth.local`,
            fullName: profile.displayName || email || 'Google User',
            is_customer: true,
            is_provider: requestedRole === 'provider',
            oauthProviders: {
              google: {
                id: profile.id,
                email,
                linkedAt: new Date(),
              },
            },
          });
          return done(null, user);
        }

        if (!user.oauthProviders?.google?.id) {
          user.oauthProviders = user.oauthProviders || {};
          user.oauthProviders.google = {
            id: profile.id,
            email,
            linkedAt: new Date(),
          };
        }
        if (requestedRole === 'provider' && !user.is_provider) {
          user.is_provider = true;
        }
        if (!user.is_customer) {
          user.is_customer = true;
        }
        if (!user.fullName && profile.displayName) {
          user.fullName = profile.displayName;
        }
        await user.save();
        done(null, user);
      } catch (err) {
        done(err);
      }
    }
  ));
}

module.exports = { configurePassport };