// Reference: https://antoinevastel.com/crawler/2018/09/20/parallel-crawler-puppeteer.html

const fs = require('fs');

function readURLFile(path) {
    //return fs.readFileSync(path, 'utf-8')
    return fs.readFileSync(path, 'ascii')
        .split("\n")
        .map((elt) => {
            let cols = elt.split(',');
            if( cols.length >= 2 ) {
                const url = cols[1].replace("\r", "");
                return `https://${url.toLowerCase()}`;
            }
        });
}

const puppeteer = require("puppeteer");

const NUM_BROWSERS = 2;
const NUM_PAGES = 3;
const DO_SCREENSHOT = false;

(async () => {
    const startDate = new Date().getTime();
    const USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5 HB) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/75.0.3770.90 Safari/537.36';
    const urls = readURLFile('/tmp/urls.csv');

    const promisesBrowsers = [];
    for (let numBrowser= 0; numBrowser < NUM_BROWSERS; numBrowser++) {
        promisesBrowsers.push(new Promise(async (resBrowser) => {
            const browser = await puppeteer.launch({
                args: [
                '--no-sandbox',
                '--disable-setuid-sandbox'
                ]
            });
            const promisesPages = [];

            for (let numPage = 0; numPage < NUM_PAGES; numPage++ ) {
                promisesPages.push(new Promise(async(resPage) => {
                    while(urls.length > 0) {
                        const url = urls.pop();
                        console.log(`Visiting url: ${url}`);
                        let page = await browser.newPage();
                        await page.setUserAgent(USER_AGENT);

                        try{
                            await page.goto(url);
                            if( DO_SCREENSHOT ) {
                                let fileName = url.replace(/(\.|\/|:|%|#)/g, "_");
                                if (fileName.length > 100) {
                                    fileName = fileName.substring(0, 100);
                                }
                                await page.screenshot({ path: `/tmp/screenshots/${fileName}.jpeg`, fullPage: true });
                            }
                        } catch(err) {
                            console.log(`An error occured on url: ${url}`);
                            console.log(`${err}`);
                        } finally {
                            await page.close();
                        }
                    }

                    resPage();
                }));
            }

            await Promise.all(promisesPages);
            await browser.close();
            resBrowser();
        }));
    }

    await Promise.all(promisesBrowsers);
    console.log(`Time elapsed ${Math.round((new Date().getTime() - startDate) / 1000)} s`);

})();
