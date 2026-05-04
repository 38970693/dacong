/**
 * Data Exporter
 * Handles export to JSON, CSV, and Markdown formats
 */

import { writeFile, mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import { createObjectCsvWriter } from 'csv-writer';

export class Exporter {
  constructor(options = {}) {
    this.outputDir = options.outputDir || './data';
  }

  async ensureDir() {
    if (!existsSync(this.outputDir)) {
      await mkdir(this.outputDir, { recursive: true });
    }
  }

  /**
   * Export data to JSON
   */
  async toJSON(data, filename = 'leaderboard.json') {
    await this.ensureDir();
    const filepath = `${this.outputDir}/${filename}`;
    const content = JSON.stringify(data, null, 2);
    await writeFile(filepath, content, 'utf-8');
    return filepath;
  }

  /**
   * Export data to CSV
   */
  async toCSV(data, filename = 'leaderboard.csv') {
    await this.ensureDir();
    const filepath = `${this.outputDir}/${filename}`;

    // Flatten data for CSV
    const records = this._flattenData(data);

    if (records.length === 0) {
      throw new Error('No data to export');
    }

    // Get headers from first record
    const headers = Object.keys(records[0]).map(key => ({
      id: key,
      title: key
    }));

    const csvWriter = createObjectCsvWriter({
      path: filepath,
      header: headers
    });

    await csvWriter.writeRecords(records);
    return filepath;
  }

  /**
   * Export data to Markdown table
   */
  async toMarkdown(data, filename = 'leaderboard.md') {
    await this.ensureDir();
    const filepath = `${this.outputDir}/${filename}`;

    const records = this._flattenData(data);
    if (records.length === 0) {
      throw new Error('No data to export');
    }

    const headers = Object.keys(records[0]);
    const markdown = this._toMarkdownTable(headers, records);

    await writeFile(filepath, markdown, 'utf-8');
    return filepath;
  }

  /**
   * Export to all formats
   */
  async toAll(data, prefix = 'leaderboard') {
    const results = {};

    try {
      results.json = await this.toJSON(data, `${prefix}.json`);
    } catch (e) {
      results.jsonError = e.message;
    }

    try {
      results.csv = await this.toCSV(data, `${prefix}.csv`);
    } catch (e) {
      results.csvError = e.message;
    }

    try {
      results.markdown = await this.toMarkdown(data, `${prefix}.md`);
    } catch (e) {
      results.markdownError = e.message;
    }

    return results;
  }

  /**
   * Flatten nested data for CSV export
   */
  _flattenData(data) {
    const records = [];

    if (Array.isArray(data)) {
      data.forEach(item => {
        records.push(this._flattenObject(item));
      });
    } else if (data.categories) {
      // LMArena style data with categories
      data.categories.forEach(category => {
        category.models.forEach(model => {
          records.push({
            ...this._flattenObject(model),
            source: data.source,
            category: category.category || category.categoryName,
            fetchedAt: data.fetchedAt
          });
        });
      });
    } else if (data.models) {
      // Simple format with models array
      data.models.forEach(model => {
        records.push({
          ...this._flattenObject(model),
          source: data.source,
          fetchedAt: data.fetchedAt
        });
      });
    }

    return records;
  }

  _flattenObject(obj, prefix = '') {
    const result = {};

    for (const key in obj) {
      if (obj.hasOwnProperty(key)) {
        const value = obj[key];
        const newKey = prefix ? `${prefix}_${key}` : key;

        if (value && typeof value === 'object' && !Array.isArray(value)) {
          Object.assign(result, this._flattenObject(value, newKey));
        } else if (Array.isArray(value)) {
          result[newKey] = value.join(', ');
        } else {
          result[newKey] = value;
        }
      }
    }

    return result;
  }

  _toMarkdownTable(headers, records) {
    const lines = [];

    // Header row
    lines.push('| ' + headers.join(' | ') + ' |');
    lines.push('| ' + headers.map(() => '---').join(' | ') + ' |');

    // Data rows
    records.forEach(record => {
      const row = headers.map(h => {
        const value = record[h] || '';
        // Escape pipe characters
        return String(value).replace(/\|/g, '\\|');
      });
      lines.push('| ' + row.join(' | ') + ' |');
    });

    return lines.join('\n');
  }
}

export default Exporter;