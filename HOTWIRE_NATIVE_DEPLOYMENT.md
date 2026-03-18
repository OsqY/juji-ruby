# HOTWIRE NATIVE - DEPLOYMENT GUIDE

## Pre-Deployment Checklist

### Code Review
```bash
# Ver todos los cambios
git log --oneline --graph --all --decorate

# Revisar cambios específicos
git show commit-hash

# Verificar que no hay secrets en código
git diff main..feature | grep -i "password\|token\|secret\|api"
```

### Tests
```bash
# Correr test suite completa
rails test

# Específicamente Hotwire Native tests
rails test:integration

# Coverage (si está configurado)
rails test --coverage
```

### Performance Baseline
```bash
# Ejecutar performance check
rake hotwire_native:performance_check

# Esperados:
# ✅ CSS < 200KB
# ✅ JS < 100KB
# ✅ <= 15 Stimulus controllers
# ✅ Mobile layouts present
```

### Local Testing
```bash
# 1. Clean build
rm -rf tmp/ log/
bundle install --local
rails db:reset

# 2. Start server
rails server -p 3000

# 3. Test in browser
# Desktop: http://localhost:3000
# Mobile DevTools: F12 → Toggle device toolbar

# 4. Test Hotwire Native simulation
# Header: User-Agent: TurboNative/1.0
curl -H "User-Agent: TurboNative/1.0" http://localhost:3000/dashboard
```

---

## Staging Deployment

### 1. Push to Staging

```bash
# If using Heroku
git push heroku main:main

# If using custom deployment
git push staging main
```

### 2. Run Migrations (if any)
```bash
heroku run "rails db:migrate" -a your-app-staging
# or
cap staging deploy:migrate
```

### 3. Verify Staging
```bash
# Check logs
heroku logs --tail -a your-app-staging

# Test endpoints
curl https://your-app-staging.herokuapp.com/dashboard

# Check headers
curl -I https://your-app-staging.herokuapp.com/dashboard
```

### 4. Mobile Testing in Staging

**iOS Simulator:**
```bash
# Open Safari
open "http://your-app-staging.herokuapp.com"

# Or test with Turbo Native iOS app
# See: https://github.com/hotwired/turbo-ios
```

**Android Emulator:**
```bash
# Connect emulator
emulator -avd your_device

# Open Chrome
adb shell am start -a android.intent.action.VIEW -d "http://your-app-staging.herokuapp.com"
```

### 5. Staging Tests

- [ ] Dashboard loads
- [ ] Navigation functional
- [ ] Create transaction (form submit)
- [ ] View reports
- [ ] Authentication works
- [ ] Logout and login
- [ ] Deep linking (if possible)
- [ ] Error pages render correctly
- [ ] Mobile layout used for native User-Agent
- [ ] CORS headers present

### 6. Performance Testing (Staging)

```bash
# From your machine
curl -o /dev/null -s -w "Time: %{time_total}s\n" https://your-app-staging.herokuapp.com/dashboard

# Expected: < 1 second
```

### 7. Security Verification

```bash
# Check security headers
curl -I https://your-app-staging.herokuapp.com/dashboard

# Should have:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
```

---

## Production Deployment

### Pre-Production Checklist

- [ ] All staging tests pass
- [ ] Code reviewed and approved
- [ ] Performance targets met
- [ ] Security headers verified
- [ ] Backup plan documented
- [ ] Rollback procedure tested
- [ ] Monitoring alerts configured
- [ ] Team notified of deployment

### Deployment Steps

#### 1. Tag Release
```bash
# Create annotated tag
git tag -a v1.0.0-hotwire-native -m "Hotwire Native integration"

# Push tag
git push origin v1.0.0-hotwire-native
```

#### 2. Deployment

**Option A: Heroku**
```bash
# Promote staging to production
heroku pipeline:promote -s your-app-staging -a your-app

# Or manual push
git push heroku main:main
```

**Option B: Custom Server (Kamal/Capistrano)**
```bash
# If using Kamal
kamal deploy

# If using Capistrano
cap production deploy
```

#### 3. Post-Deployment Monitoring

```bash
# Watch logs
heroku logs --tail -a your-app

# Or
tail -f ~/apps/juji-ruby/log/production.log
```

#### 4. Smoke Tests (In Production)

```bash
# Health check
curl -I https://your-app.com/up

# Dashboard
curl -I https://your-app.com/dashboard

# Check native client header
curl -I -H "User-Agent: TurboNative/1.0" https://your-app.com/dashboard
# Should see: X-Hotwire-Native: true
```

#### 5. Verify Critical Functionality

- [ ] Login/Registration works
- [ ] Dashboard loads
- [ ] Can create transactions
- [ ] Navigation smooth
- [ ] No error responses (5xx)
- [ ] Performance acceptable

### 6. Monitor for 24 Hours

```bash
# Watch for errors
grep "ERROR\|5[0-9][0-9]" log/production.log

# Monitor specific patterns
grep "X-Hotwire-Native" log/production.log | tail -20

# Check user activity
grep "GET /dashboard\|GET /transactions" log/production.log | wc -l
```

---

## Rollback Procedure (If Needed)

### Immediate Rollback

**Heroku:**
```bash
# Revert to previous release
heroku releases --app your-app
# See: Release 123
#
heroku rollback v123 -a your-app
```

**Capistrano:**
```bash
cap production deploy:rollback
```

**Manual:**
```bash
# Revert git
git revert HEAD

# Push
git push origin main
```

### Post-Rollback

1. Verify rollback successful
```bash
curl https://your-app.com/dashboard
```

2. Check logs for errors
3. Notify team
4. Document what went wrong
5. Fix issue in separate branch
6. Re-deploy after fix

---

## Environment Variables for Production

### Required Variables

```bash
# Database
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# Hotwire Native
CORS_ORIGINS=https://your-domain.com

# Security
SECRET_KEY_BASE=<very-long-random-string>
```

### Set Variables

**Heroku:**
```bash
heroku config:set CORS_ORIGINS=https://your-app.com -a your-app
heroku config:set RAILS_LOG_LEVEL=info -a your-app
```

**Custom Server:**
```bash
# Edit .env or systemd service
export CORS_ORIGINS="https://your-app.com"
export RAILS_LOG_LEVEL="info"
```

---

## Build Files for Native Apps

### iOS App Build

**After server deployment:**

1. Update Turbo Native iOS app URL
```swift
// In AppDelegate
Turbo.session.webViewConfiguration.preferences.javaScriptEnabled = true
Turbo.session.visit(URL(string: "https://your-app.com")!)
```

2. Build in Xcode
```bash
xcode-build archive -workspace Turbo.xcworkspace -scheme TurboNative
```

3. Upload to TestFlight
4. Submit to App Store

### Android App Build

**After server deployment:**

1. Update Turbo Native Android app URL
```kotlin
// In MainActivity
val session = TurboSession("https://your-app.com")
session.webView.settings.javaScriptEnabled = true
```

2. Build APK
```bash
./gradlew assembleRelease
```

3. Upload to Firebase App Distribution
4. Submit to Play Store

---

## Monitoring After Deployment

### Error Tracking

**Setup with Sentry:**
```ruby
# In config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.enabled_environments = %w[production]
end
```

### Analytics

Track:
- Native client percentage
- Error rates per platform
- Page load times
- User engagement

### Alerts

Configure alerts for:
- Error rate > 1%
- Response time > 2s
- 5xx errors spike
- Deep link failures

---

## Release Notes Template

```markdown
# Juji 1.0.0 - Hotwire Native Support

## What's New

✨ **Native Mobile Apps**
- iOS app available on App Store
- Android app available on Google Play
- Same code, consistent experience

**Improvements**
- Bottom tab navigation
- Touch-optimized forms
- Deep linking support
- Better error pages

**Bug Fixes**
- [List specific fixes]

## How to Update

**iOS:** Update from App Store  
**Android:** Update from Google Play  
**Web:** No action needed, automatically updated

## Known Issues

- [List any known issues]

## Support

For issues: support@your-app.com  
GitHub: your-repo/issues

---

_Release Date: March 18, 2026_
```

---

## Post-Deployment Communication

### To Users
```
Subject: 🚀 Juji Now Available as Native App!

Hi there,

We're excited to announce that Juji is now available as native apps for iOS and Android! Download from:

📱 iOS: https://apps.apple.com/...
🤖 Android: https://play.google.com/...

All your data is synced across web and mobile. Enjoy!

— The Juji Team
```

### To Team
```
✅ Hotwire Native deployment successful!

Timeline:
- Deployed: [timestamp]
- Tests: All passing
- Monitoring: Active
- Status: GREEN

Next steps:
1. Native app builds (iOS/Android)
2. TestFlight/Beta release
3. App Store submission

Questions? See: HOTWIRE_NATIVE_MAINTENANCE.md
```

---

## Success Metrics (Track These)

| Metric | Target | Actual |
|--------|--------|--------|
| Deployment time | < 10 min | __ |
| Tests passing | 100% | __ |
| Health check | 200 OK | __ |
| API response time | < 500ms | __ |
| Error rate | < 0.1% | __ |
| Native traffic | > 0% | __ |

---

## Troubleshooting Deployment Issues

### Issue: Migration Failed
```bash
# Check status
heroku run "rails db:migrate:status" -a your-app

# Rollback migration
heroku run "rails db:rollback STEP=1" -a your-app

# Check logs
heroku logs --tail
```

### Issue: Asset compilation failed
```bash
# Clear cache
rails assets:clobber

# Recompile
rails assets:precompile

# Push again
git push heroku main:main
```

### Issue: Slow response time
```bash
# Check database
heroku pg:info -a your-app

# Check dyno
heroku ps -a your-app

# Scale if needed
heroku ps:scale web=2 -a your-app
```

---

## Final Deployment Checklist

Before hitting "Deploy":

- [ ] Code reviewed ✓
- [ ] Tests passing ✓
- [ ] Staging verified ✓
- [ ] Performance acceptable ✓
- [ ] Security headers set ✓
- [ ] Monitoring configured ✓
- [ ] Rollback plan ready ✓
- [ ] Team notified ✓
- [ ] Backup available ✓
- [ ] Release notes prepared ✓

**Status: 🟢 READY FOR DEPLOYMENT**

---

_Questions? See HOTWIRE_NATIVE_*.md files or ask your team lead._

**Good luck! 🚀**
