'use strict';
const { createApp } = require('./app');
const port = process.env.PORT || 3013;
createApp().listen(port, () => console.log(`SecureDB API demo: http://localhost:${port}`));
