#!/usr/bin/env node
'use strict';
const assert = require('assert');
const sharp = require('sharp');

const roundedCornerResizer = sharp()
  .resize(200, 200)
  .composite([
    {input: Buffer.from('<svg><rect x="0" y="0" width="200" height="200" rx="50" ry="50"/></svg>')},
  ])
  .png();

new Promise((resolve, reject) => {
  roundedCornerResizer.toBuffer(function (err, data, info) {
    if (err) {
      reject(err);
      return;
    }

    resolve(data);
    return;
  });
})
  .then((data) => {
    assert.strictEqual(true, data.length > 0);

    process.exit(0);
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
