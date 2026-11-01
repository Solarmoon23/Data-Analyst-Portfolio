# DCLC Vehicle & Expense Log

A mobile-friendly web app for logging business trips, fuel and meal expenses, with every entry saved to a Google Sheet for reporting. Built for Deep Creek Lake Concierge's field-service work.

   ![App screenshot](log%20form.png)

## The problem
Mileage, fuel and meal receipts were tracked inconsistently, making tax-time deductions and job costing slow and error-prone.

## How it works
```
Phone browser (HTML form on Netlify)
        │  POST
        ▼
Google Apps Script web app
        │
        ▼
Google Sheet  →  summaries / charts
```
- **Front end:** static HTML/CSS/JavaScript form hosted on Netlify
- **Back end:** Google Apps Script web app receives entries and appends rows
- **Data store:** Google Sheet — one row per trip or expense, ready for pivot tables and reporting

## Features
- Log trips (purpose, miles), fuel purchases and meals
- Timestamped, structured records for easy filtering by date, category or job
- No server or database costs

## Skills demonstrated
- Data collection design (clean, consistent input → clean data)
- Apps Script automation and API-style integration
- Spreadsheet data modeling and reporting

## Setup
1. Create a Google Sheet and deploy `apps-script/Code.gs` as a web app.
2. Put the deployment URL in `config.js` (see `config.example.js`).
3. Deploy the `/site` folder to Netlify.

> ⚠️ The live Apps Script URL is not included — anyone with it could write to the sheet.
