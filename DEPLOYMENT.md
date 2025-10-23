# TwinForge - Deployment Guide

This guide explains how to configure environment variables for different deployment environments.

## Environment Types

TwinForge supports three environments:

1. **Development** - Local development on your machine
2. **Staging** - Netlify deploy previews and staging site
3. **Production** - Live production site

## Local Development Setup

### 1. Create your local .env file

```bash
# Copy the example file
cp .env.example .env

# Or for development-specific config
cp .env.development.example .env.development
```

### 2. Fill in your Supabase credentials

Get your credentials from: https://app.supabase.com/project/_/settings/api

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Start development server

```bash
npm run dev
```

## Netlify Deployment Setup

### Staging Environment

1. Go to Netlify Dashboard → Your Site → Site Settings → Environment Variables
2. Add variables for **Deploy Previews**:

```
VITE_SUPABASE_URL=https://kwipydbtjagypocpvbwn.supabase.co
VITE_SUPABASE_ANON_KEY=<your-staging-anon-key>
VITE_ENABLE_VOICE_COACH=true
VITE_ENABLE_3D_AVATAR=true
VITE_ENABLE_WEARABLES=true
VITE_ENABLE_STRICT_MODE=false
VITE_DEBUG_MODE=false
```

### Production Environment

1. Go to Netlify Dashboard → Your Site → Site Settings → Environment Variables
2. Add variables for **Production** (same keys, different values):

```
VITE_SUPABASE_URL=https://kwipydbtjagypocpvbwn.supabase.co
VITE_SUPABASE_ANON_KEY=<your-production-anon-key>
VITE_ENABLE_VOICE_COACH=true
VITE_ENABLE_3D_AVATAR=true
VITE_ENABLE_WEARABLES=true
VITE_ENABLE_STRICT_MODE=false
VITE_DEBUG_MODE=false
```

## Security Checklist

### Before Deploying to Production

- [ ] Rotate Supabase anon keys if they were ever committed to git
- [ ] Verify no private keys (SECRET, PRIVATE, SERVICE_ROLE) are in .env
- [ ] Check that .env is in .gitignore
- [ ] Confirm all Edge Functions use server-side environment variables
- [ ] Test CSP headers are active
- [ ] Verify HSTS header is enabled
- [ ] Run security audit: `npm audit`
- [ ] Test all critical flows in staging first

### Rotating Supabase Keys

If your Supabase anon key was compromised:

1. Go to Supabase Dashboard → Settings → API
2. Click "Generate new anon key"
3. Update the key in:
   - Netlify environment variables (Production)
   - Netlify environment variables (Deploy Previews)
   - Your local .env file (if using the same project)
4. Deploy to production
5. Old key becomes invalid after rotation

## Environment Variable Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VITE_SUPABASE_URL` | ✅ Yes | - | Your Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | ✅ Yes | - | Your Supabase anon key (public, safe to expose) |
| `VITE_ENABLE_VOICE_COACH` | ❌ No | `true` | Enable voice coach feature |
| `VITE_ENABLE_3D_AVATAR` | ❌ No | `true` | Enable 3D avatar viewer |
| `VITE_ENABLE_WEARABLES` | ❌ No | `true` | Enable wearables integration |
| `VITE_ENABLE_STRICT_MODE` | ❌ No | `true` (dev) | Enable React StrictMode |
| `VITE_DEBUG_MODE` | ❌ No | `false` | Enable verbose logging |

## Troubleshooting

### "Configuration Error" on startup

This means required environment variables are missing or invalid.

**Solution:**
1. Check browser console for specific error
2. Verify `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` are set
3. Ensure URL includes "supabase.co" or "supabase.in"
4. Verify anon key is at least 100 characters

### Environment variables not updating

After changing environment variables in Netlify:

1. Clear build cache: Deploys → Trigger deploy → Clear cache and deploy
2. Verify variables are set for the correct scope (Production vs Deploy Previews)

### CSP blocking resources

If Content Security Policy blocks resources:

1. Check browser console for CSP violation reports
2. Add allowed domain to `netlify.toml` CSP header
3. Test in staging before production

## Need Help?

- Supabase Docs: https://supabase.com/docs
- Netlify Docs: https://docs.netlify.com
- Security Issues: Contact security@yourcompany.com
