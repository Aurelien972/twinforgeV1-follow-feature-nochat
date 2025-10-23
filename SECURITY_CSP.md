# Content Security Policy (CSP) - TwinForge

## Current Status: REPORT-ONLY MODE

The CSP is currently in **report-only mode**, which means:
- ✅ Violations are logged to browser console
- ✅ No functionality is blocked
- ⚠️ Not yet enforcing security (testing phase)

## What is CSP?

Content Security Policy (CSP) is a security layer that helps prevent:
- Cross-Site Scripting (XSS) attacks
- Data injection attacks
- Clickjacking
- Other code injection attacks

## Current Policy Breakdown

### `default-src 'self'`
- Only allow resources from same origin by default
- Prevents loading scripts/styles/images from untrusted sources

### `script-src 'self' 'unsafe-inline' 'unsafe-eval'`
- Allow scripts from same origin
- `unsafe-inline`: Required for React inline event handlers
- `unsafe-eval`: Required for some React development tools
- **TODO**: Remove unsafe-* in future by using nonces

### `style-src 'self' 'unsafe-inline'`
- Allow styles from same origin
- `unsafe-inline`: Required for Tailwind CSS and Framer Motion
- Also allows Google Fonts stylesheets

### `font-src 'self' https://fonts.gstatic.com`
- Allow fonts from same origin and Google Fonts CDN

### `img-src 'self' data: https: blob:`
- Allow images from same origin
- `data:`: Base64 encoded images
- `https:`: All HTTPS images (avatar uploads, meal photos)
- `blob:`: Webcam captures and generated images
- Supabase Storage for user uploads

### `connect-src` (API calls)
- Supabase: https://kwipydbtjagypocpvbwn.supabase.co
- Supabase Realtime: wss://kwipydbtjagypocpvbwn.supabase.co
- OpenAI API: https://api.openai.com
- **Note**: Other APIs should be proxied through Edge Functions

### `media-src` (Audio/Video)
- Allow media from same origin and Supabase Storage
- `blob:`: Recorded audio (voice coach, meal descriptions)

### `object-src 'none'`
- Block all plugins (Flash, Java, etc.)
- Modern web apps don't need these

### `frame-src 'none'`
- Block embedding of iframes
- Prevents clickjacking attacks

### `base-uri 'self'`
- Prevent base tag injection attacks

### `form-action 'self'`
- Forms can only submit to same origin
- Prevents form hijacking

### `frame-ancestors 'none'`
- Prevent this site from being embedded in iframes
- Additional clickjacking protection

### `upgrade-insecure-requests`
- Automatically upgrade HTTP to HTTPS
- Prevents mixed content errors

## Monitoring CSP Violations

### In Development (Report-Only Mode)

1. Open browser DevTools → Console
2. Look for CSP violation reports:
   ```
   [Report Only] Refused to load the script 'https://evil.com/script.js'
   because it violates the following Content Security Policy directive: ...
   ```

3. If you see violations for legitimate resources:
   - Add the domain to the appropriate directive in `netlify.toml`
   - Example: Add `https://new-cdn.com` to `script-src`

### Common Violations and Fixes

#### Violation: Inline script blocked
```
Refused to execute inline script because it violates CSP directive
```
**Fix**: Move inline scripts to external files OR use nonces

#### Violation: External resource blocked
```
Refused to load script from 'https://unknown-cdn.com'
```
**Fix**: Add domain to appropriate directive:
```toml
script-src 'self' https://unknown-cdn.com;
```

#### Violation: eval() blocked
```
Refused to evaluate a string as JavaScript
```
**Fix**: Refactor code to avoid eval() OR add 'unsafe-eval' (not recommended)

## Roadmap to Strict CSP

### Phase 1: Report-Only (Current) ✅
- Monitor violations for 1-2 weeks
- Identify all legitimate external resources
- No blocking, only logging

### Phase 2: Add Nonces (Future)
- Generate unique nonces for inline scripts
- Replace 'unsafe-inline' with nonce-based approach
- Use Netlify Edge Functions for nonce generation

### Phase 3: Remove unsafe-* (Future)
- Eliminate 'unsafe-inline' and 'unsafe-eval'
- Use strict-dynamic for better security
- Achieve A+ rating on securityheaders.com

### Phase 4: Enforce CSP (Future)
- Switch from Content-Security-Policy-Report-Only to Content-Security-Policy
- Block all violations
- Monitor error reports from production

## Testing CSP

### Manual Testing

1. Deploy to staging with CSP report-only
2. Navigate through all app features:
   - [ ] Body scan (webcam access)
   - [ ] Meal scan (camera + barcode)
   - [ ] Fridge scan (multi-photo upload)
   - [ ] Voice coach (microphone access)
   - [ ] 3D avatar (Three.js rendering)
   - [ ] Activity tracking (wearables API)
   - [ ] Profile (image uploads)
3. Check console for CSP violations
4. Fix violations or whitelist domains

### Automated Testing (Future)

Use tools like:
- CSP Evaluator: https://csp-evaluator.withgoogle.com/
- SecurityHeaders.com: https://securityheaders.com/
- Mozilla Observatory: https://observatory.mozilla.org/

## Adding New External Resources

When integrating a new third-party service:

1. Identify what resources it needs:
   - Scripts: Add to `script-src`
   - Styles: Add to `style-src`
   - API calls: Add to `connect-src`
   - Images: Add to `img-src`

2. Update netlify.toml:
```toml
Content-Security-Policy-Report-Only = """
  ...
  script-src 'self' 'unsafe-inline' https://new-service.com;
  connect-src 'self' https://api.new-service.com;
  ...
"""
```

3. Test in staging before production

## Security Best Practices

### DO ✅
- Always start with report-only mode
- Monitor violations before enforcing
- Use specific domains instead of wildcards
- Keep CSP as strict as possible
- Document every domain added and why

### DON'T ❌
- Never use `'unsafe-inline' 'unsafe-eval'` in production long-term
- Avoid wildcards like `https://*` (too permissive)
- Don't ignore CSP violations
- Don't add domains without understanding why
- Never disable CSP completely

## Need Help?

- CSP Guide: https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
- CSP Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html
- Report Issues: Contact security team

## Activation Checklist

Before switching from report-only to enforce mode:

- [ ] Monitor violations for at least 1 week in staging
- [ ] Zero legitimate resource violations
- [ ] All features tested and working
- [ ] CSP Evaluator shows no critical issues
- [ ] SecurityHeaders.com shows A or A+ rating
- [ ] Team approved for production deployment
