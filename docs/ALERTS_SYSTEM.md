# Automated Alerts System

## Overview
The application includes an automated alerts system that monitors users for:
- Budget exceeded (current month)
- No daily reports (3+ days)
- Project staleness (7+ days without activity)

## Configuration

### Manual Execution
Run alerts check manually:
```bash
bundle exec rake alerts:check_all
```

Or enqueue as a background job:
```ruby
CheckAlertsJob.perform_now
# or
CheckAlertsJob.perform_later
```

### Automatic Execution (Production)

#### Option 1: System Cron
Add to crontab to run every 30 minutes:
```bash
*/30 * * * * cd /path/to/app && bundle exec rake alerts:check_all >> log/cron.log 2>&1
```

#### Option 2: Solid Queue (Rails 8)
The application uses Solid Queue for job management. To schedule alerts to run automatically:

```ruby
# In config/initializers/solid_queue.rb or similar
# Create a scheduled execution that repeats every 30 minutes
Solid::Queue::ScheduledExecution.find_or_create_by(job_class_name: "CheckAlertsJob") do |execution|
  execution.scheduled_at = Time.current
  execution.repeat_interval = 30.minutes
end
```

#### Option 3: Heroku Scheduler
Add a Heroku scheduler task:
```
bundle exec rake alerts:check_all
```
Schedule to run every 30 minutes or hourly.

## Testing

Run the test suite to verify alert functionality:
```bash
bundle exec rails test test/services/alert_service_test.rb
```

## Alert Service Details

The `AlertService` provides three main checks:

### 1. Budget Exceeded
- **Condition**: Current month expenses > budget limit
- **Message**: "Presupuesto superado - Has gastado L. X.XX, superando el límite de L. Y.YY por L. Z.ZZ"
- **Level**: danger (red)

### 2. No Reports (3 Days)
- **Condition**: No daily report submitted in 3+ days
- **Message**: "No has enviado reporte diario en N días (>= 3)"
- **Level**: warning (yellow)

### 3. Project No Progress
- **Condition**: Project has no activity (task updates) for 7+ days
- **Message**: "Proyecto 'X' sin actividad hace más de 7 días"
- **Level**: warning (yellow)
- **Limit**: Shows up to 3 projects; if 5+, shows "Project A y Project B y 2 mas"

## Implementation Details

```ruby
# Services
AlertService.check_for_user(user)      # Returns array of alerts for user
AlertService.check_budget_exceeded(user)
AlertService.check_no_reports_3_days(user)
AlertService.check_project_no_progress(user)
AlertService.check_all_users            # Executes checks for all users

# Each alert is a hash:
{
  type: :budget_exceeded,
  level: :danger,
  title: "Presupuesto superado",
  message: "..."
}

# Notifications are auto-created in database from alerts
# Users see alerts in the notifications center (/notifications)
```

## Database Schema

Alerts are stored as `Notification` records:
- `notification_type`: alert type (budget_exceeded, no_report_3_days, project_no_progress)
- `message`: human-readable alert message
- `read_at`: timestamp when user read the alert
- `user_id`: which user the alert is for

## Performance Considerations

- Checks are optimized with `.joins()` to avoid N+1 queries
- Limit to 3 projects per user to prevent excessive notifications
- Uses `find_or_create_by` to avoid duplicate notifications
- Respects user privacy (each user only sees their own alerts)

## Future Enhancements

- [ ] Email notifications for critical alerts
- [ ] SMS alerts for budget exceeded
- [ ] Configurable alert thresholds per user
- [ ] Alert suppression/snooze functionality
- [ ] Webhook integrations for external systems
- [ ] Analytics dashboard for alert patterns
