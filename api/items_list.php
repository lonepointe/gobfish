<?php
declare(strict_types=1);
header('Content-Type: application/json');
require __DIR__ . '/_auth.php';          // check session/token & role
require __DIR__ . '/_db.php';            // returns $pdo (PDO to SQLite)

// Inputs from Tabulator (ajaxURLGenerator/params)
$page    = max(1, (int)($_GET['page'] ?? 1));
$size    = min(200, max(1, (int)($_GET['size'] ?? 25)));
$sort    = $_GET['sort'] ?? '';          // e.g. "name|asc"
$q       = trim((string)($_GET['q'] ?? ''));  // simple search

$offset  = ($page - 1) * $size;

// Whitelist sortable columns
$sortable = ['id','name','category','rarity','updated_at'];
$orderSql = 'id DESC';
if ($sort) {
  [$col, $dir] = array_pad(explode('|', $sort, 2), 2, 'asc');
  $col = in_array($col, $sortable, true) ? $col : 'id';
  $dir = strtolower($dir) === 'desc' ? 'DESC' : 'ASC';
  $orderSql = "$col $dir";
}

$where = [];
$params = [];
if ($q !== '') {
  $where[] = '(name LIKE :q OR category LIKE :q OR rarity LIKE :q)';
  $params[':q'] = "%$q%";
}
$whereSql = $where ? 'WHERE ' . implode(' AND ', $where) : '';

$total = (int)$pdo->prepare("SELECT COUNT(*) FROM items $whereSql")
                  ->execute($params) ?: 0;
$total = (int)$pdo->query("SELECT COUNT(*) FROM items $whereSql")
                  ->fetchColumn();

$sql = "SELECT id,name,category,rarity,notes,updated_at
        FROM items
        $whereSql
        ORDER BY $orderSql
        LIMIT :size OFFSET :offset";
$stmt = $pdo->prepare($sql);
foreach ($params as $k => $v) $stmt->bindValue($k, $v, PDO::PARAM_STR);
$stmt->bindValue(':size', $size, PDO::PARAM_INT);
$stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo json_encode([
  'data' => $rows,
  'page' => $page,
  'size' => $size,
  'total'=> $total,
]);
