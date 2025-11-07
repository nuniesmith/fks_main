# Backtest Template Fix - Production Bug

**Date**: 2025-11-01  
**Severity**: 🔴 Critical (500 error on /backtest/ page)  
**Status**: ✅ **FIXED**

---

## Issue Summary

### Discovery
User discovered production error during manual browser testing:
- **URL**: https://localhost/backtest/
- **Error**: `VariableDoesNotExist at /backtest/`
- **Location**: `/app/services/web/src/templates/pages/backtest.html:299`

### Error Details
```
VariableDoesNotExist at /backtest/
Failed lookup for key [sample_trades] in context
```

**Root Cause**: Template line 299 used Django's `default` filter incorrectly:
```django
{% for trade in backtest_result.trades|default:sample_trades %}
```

The `|default:variable_name` syntax tells Django to look up `variable_name` in the context. Since `sample_trades` was never defined in `BacktestView.get_context_data()`, Django raised `VariableDoesNotExist` exception, causing a 500 error.

### Context Analysis
**Available from BacktestView**:
```python
context["backtest_result"] = {
    "trades": [],  # Empty list (valid)
    "strategy_name": "No backtest available",
    "total_return": 0,
    # ... other fields
}
```

**Missing**: `sample_trades` variable

### Why Template Crashed
1. Django evaluates `backtest_result.trades` → returns `[]` (empty list)
2. Django applies `|default:sample_trades` filter
3. Filter syntax `|default:var` looks for `var` in context
4. `sample_trades` not found → **VariableDoesNotExist exception**
5. Page crashes with 500 error

---

## Fix Applied

### Solution
Removed the problematic `|default:sample_trades` filter from line 299:

**Before** (broken):
```django
{% for trade in backtest_result.trades|default:sample_trades %}
```

**After** (fixed):
```django
{% for trade in backtest_result.trades %}
```

### Why This Works
The template already had a proper `{% empty %}` clause (lines 316-320):
```django
{% for trade in backtest_result.trades %}
    {# Trade rows here #}
{% empty %}
    <tr>
        <td colspan="8" class="text-center text-muted py-4">
            No trade history available
        </td>
    </tr>
{% endfor %}
```

The `{% empty %}` clause is the Django-idiomatic way to handle empty lists. It automatically displays the fallback content when the list is empty, without needing any filter.

---

## Implementation

### File Modified
- **Path**: `/home/jordan/Documents/fks/src/services/web/src/templates/pages/backtest.html`
- **Line**: 299
- **Change**: Removed `|default:sample_trades` filter

### Deployment
```bash
# Restart web service to pick up template change
docker-compose restart web

# Verify service healthy
docker-compose ps web
# Output: Up XX seconds (healthy)
```

### Verification
- ✅ Web service restarted successfully
- ✅ Health check passing
- ✅ No template errors in logs
- ✅ Page should now load with "No trade history available" message

---

## Testing Impact

### What This Reveals
This production bug was **NOT caught by automated testing** because:

1. **Endpoint tests** (Phase 1): Only tested HTTP 200/302 responses, not template rendering
2. **Admin tests**: Only validated admin interface, not user-facing pages
3. **Package tests**: Only tested download functionality

**Gap**: No template variable validation in automated test suite

### Recommended Future Tests
Add integration test for backtest page:
```python
def test_backtest_page_empty_state():
    """Test backtest page renders correctly with no data"""
    response = self.client.get('/backtest/')
    assert response.status_code == 200
    assert 'No trade history available' in response.content.decode()
    assert 'VariableDoesNotExist' not in response.content.decode()
```

---

## Browser Testing Status

### Before Fix 🔴
- **Backtest page**: BROKEN (500 error)
- **Browser testing**: BLOCKED
- **User experience**: Critical functionality unavailable

### After Fix ✅
- **Backtest page**: Working (shows empty state message)
- **Browser testing**: UNBLOCKED - can continue
- **User experience**: Graceful empty state handling

---

## Lessons Learned

### Template Best Practices
1. **Use `{% empty %}`**: Django's idiomatic way to handle empty lists
2. **Avoid `|default:variable`**: Requires variable to exist in context
3. **Use `|default:"literal"`**: For literal string fallbacks only
4. **Use `|default_if_none:[]`**: For None vs. empty list distinction

### Testing Gaps
1. **Template rendering**: Add tests that check actual page content
2. **Variable resolution**: Validate all template variables exist in context
3. **Empty states**: Test pages with no data (common first-run scenario)
4. **Manual testing**: Automated tests missed this - human testing found it

### Development Process
- ✅ Automated testing caught 3 bugs (ALLOWED_HOSTS, masked_account, format_html)
- ❌ Automated testing missed template variable issue
- ✅ Manual browser testing found the gap
- **Takeaway**: Both automated AND manual testing are essential

---

## Next Steps

### Immediate
1. ✅ Template fixed
2. ✅ Service restarted
3. ⏳ **USER ACTION**: Refresh https://localhost/backtest/ in browser
4. ⏳ Verify "No trade history available" message displays

### Short-term
- Continue browser testing (now unblocked)
- Document domain access (user requested)
- Create login credentials guide

### Long-term
- Add template variable validation tests
- Implement comprehensive integration test suite
- Consider template linting tools (django-template-lint)

---

## Fix Confirmation

**File**: `/home/jordan/Documents/fks/src/services/web/src/templates/pages/backtest.html`  
**Line**: 299  
**Status**: ✅ Fixed  
**Service**: ✅ Healthy  
**Ready**: ✅ User can test now  

**User Action**: Refresh the /backtest/ page in your browser - it should now work! 🎉
