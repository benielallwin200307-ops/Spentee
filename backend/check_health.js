// Quick health check script for Spentee AI backend startup verification
fetch('http://localhost:3000/health')
  .then((res) => {
    if (!res.ok) process.exit(1);
    return res.json();
  })
  .then((data) => {
    if (data && data.status === 'ok') {
      if (process.argv.includes('--summary')) {
        console.log('   - API Key Status:        ' + (data.configured ? 'Configured [OK]' : 'Unconfigured [Setup Required]'));
        console.log('   - Active Model:          ' + data.model);
      }
      process.exit(0);
    }
    process.exit(1);
  })
  .catch(() => {
    process.exit(1);
  });
