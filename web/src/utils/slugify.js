function toSlug(str) {
  if (!str) return '';
  return str
    .toString()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[đĐ]/g, 'd')
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

async function generateUniqueSlug(db, title, excludePostId = null) {
  let baseSlug = toSlug(title);
  if (!baseSlug) baseSlug = 'bai-viet';

  let query = 'SELECT slug FROM posts WHERE (slug = $1 OR slug ~ $2)';
  let params = [baseSlug, `^${baseSlug}-[0-9]+$`];

  if (excludePostId) {
    query += ' AND id != $3';
    params.push(excludePostId);
  }

  const { rows } = await db.query(query, params);
  if (rows.length === 0) {
    return baseSlug;
  }

  const existingSlugs = new Set(rows.map(r => r.slug));
  if (!existingSlugs.has(baseSlug)) {
    return baseSlug;
  }

  let counter = 2;
  while (existingSlugs.has(`${baseSlug}-${counter}`)) {
    counter++;
  }
  return `${baseSlug}-${counter}`;
}

module.exports = {
  toSlug,
  generateUniqueSlug
};