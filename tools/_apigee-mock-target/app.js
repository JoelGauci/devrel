const express = require('express');
const { createMockMiddleware } = require('openapi-mock-express-middleware');

const app = express();

app.use(
  '/api', // root path for the mock server
  createMockMiddleware({ 
    spec: '/usr/src/app/openapi.yaml',
    locale: 'en', // json-schema-faker locale, default to 'en'
    options: { // json-schema-faker options
      alwaysFakeOptionals: true,
      useExamplesValue: true
    },
 }),
);

app.listen(process.env.PORT || 9000, () => {
  let port = process.env.PORT || 9000;	
  console.log('Mock Server Listening on port ' + port + '...')
});
