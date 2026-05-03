const puppeteer = require('puppeteer-core');
const path = require('path');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const HTML   = path.resolve(__dirname, 'catalog.html');
const OUT    = path.resolve(__dirname, 'EXHIBITION-CATALOG.pdf');

(async () => {
  console.log('Launching Chrome…');
  const browser = await puppeteer.launch({
    executablePath: CHROME,
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  const page = await browser.newPage();

  // Load HTML; wait for fonts (networkidle0 waits for Google Fonts)
  console.log('Loading catalog.html…');
  await page.goto(`file:///${HTML.replace(/\\/g, '/')}`, {
    waitUntil: 'networkidle0',
    timeout: 30_000,
  });

  // Extra wait for webfonts to render
  await new Promise(r => setTimeout(r, 2000));

  console.log('Generating PDF…');
  await page.pdf({
    path: OUT,
    format: 'A4',
    printBackground: true,
    margin: { top: '0', right: '0', bottom: '0', left: '0' },
    preferCSSPageSize: true,
  });

  await browser.close();
  console.log(`\nDone! → ${OUT}`);
})();
