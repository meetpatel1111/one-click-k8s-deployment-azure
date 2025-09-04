// ---------- Config / State ----------
const API = '/api';
const PAGE = window.PAGE || 'dashboard'; // 'dashboard' or 'table'
const isTable = PAGE === 'table';

let transactions = []; // {id, description?, notes, type, category, amount, date, recurring?}
let sortKey = 'date';
let sortDir = 'desc';
let filters = { q:'', type:'', category:'', from:'', to:'' };
let currentPage = 1; 
let pageSize = 25;
let editId = null;

// ---------- DOM Refs ----------
// Common
const currencyEl = document.getElementById('currencySelect');
const themeToggle = document.getElementById('themeToggle');
const addBtn = document.getElementById('addBtn');
const modal = document.getElementById('modal');
const modalTitle = document.getElementById('modalTitle');
const closeModalBtn = document.getElementById('closeModal');
const form = document.getElementById('transactionForm');
const dateEl = document.getElementById('date');
const typeEl = document.getElementById('type');
const categoryEl = document.getElementById('category');
const amountEl = document.getElementById('amount');
const notesEl = document.getElementById('notes');
const recurringEl = document.getElementById('recurring');

// Dashboard
const incomeEl = document.getElementById('income');
const expensesEl = document.getElementById('expenses');
const balanceEl = document.getElementById('balance');
const goalLabel = document.getElementById('goalLabel');
const goalProgress = document.getElementById('goalProgress');
const quickFood = document.getElementById('quickFood');
const quickRent = document.getElementById('quickRent');
const quickSalary = document.getElementById('quickSalary');
let charts = { category: null, monthly: null };

// Table
const tbody = document.getElementById('transactionsBody');
const ths = document.querySelectorAll('#txnTable thead th[data-sort]');
const exportCsvBtn = document.getElementById('exportCsv');
const exportJsonBtn = document.getElementById('exportJson');
const importFile = document.getElementById('importFile');
const rowCount = document.getElementById('rowCount');
const pageInfo = document.getElementById('pageInfo');
const prevPage = document.getElementById('prevPage');
const nextPage = document.getElementById('nextPage');
const pageSizeEl = document.getElementById('pageSize');

// Shared filters
const searchEl = document.getElementById('search');
const typeFilter = document.getElementById('typeFilter');
const categoryFilter = document.getElementById('categoryFilter');
const fromDate = document.getElementById('fromDate');
const toDate = document.getElementById('toDate');
const clearFilters = document.getElementById('clearFilters');

// ---------- Helpers ----------
const fmt = n => (Number(n)||0).toLocaleString(undefined, { minimumFractionDigits:2, maximumFractionDigits:2 });
const cid = () => Date.now() + '-' + Math.random().toString(16).slice(2);

function applyTheme(theme) {
  document.body.classList.toggle('dark', theme === 'dark');
}

function getMonthKey(date) {
  const dt = new Date(date);
  return dt.getFullYear() + '-' + String(dt.getMonth()+1).padStart(2,'0');
}

function download(name, content, type='text/plain'){
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([content], { type }));
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

// ---------- API Calls ----------
async function loadTxns(){
  const res = await fetch(`${API}/transactions`);
  transactions = await res.json();
}
async function createTxn(txn){
  // Ensure amount sign matches type
  let amt = Number(txn.amount) || 0;
  amt = txn.type === 'expense' ? -Math.abs(amt) : Math.abs(amt);

  const payload = {
    id: txn.id || cid(),
    date: txn.date,
    type: txn.type,
    category: txn.category || 'Other',
    amount: amt,
    notes: txn.notes || '',
    recurring: !!txn.recurring
  };

  const res = await fetch(`${API}/transactions`, {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify(payload)
  });
  return res.json();
}

async function updateTxn(id, txn){
  // Ensure amount sign matches type
  let amt = Number(txn.amount) || 0;
  amt = txn.type === 'expense' ? -Math.abs(amt) : Math.abs(amt);

  const payload = {
    date: txn.date,
    type: txn.type,
    category: txn.category || 'Other',
    amount: amt,
    notes: txn.notes || '',
    recurring: !!txn.recurring
  };

  await fetch(`${API}/transactions/${id}`, {
    method:'PUT',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify(payload)
  });
}

async function deleteTxn(id){
  await fetch(`${API}/transactions/${id}`, { method:'DELETE' });
}

async function getSummary(){
  const res = await fetch(`${API}/summary`);
  return res.json();
}

async function exportCsv(){
  const r = await fetch(`${API}/export`);
  return r.text();
}

// ---------- Transform Data ----------
function normalize(trans){
  return trans.map(t => ({
    id: t.id,
    date: t.date,
    type: (Number(t.amount) >= 0 ? 'income' : 'expense') || 'expense',
    category: t.category || 'Other',
    amount: Math.abs(Number(t.amount) || 0),
    notes: t.notes || t.description || '',
    recurring: !!t.recurring
  }));
}

// ---------- Filters, Sorting, Paging ----------
function filtered(){
  let list = normalize(transactions);
  const q = (filters.q||'').toLowerCase();

  if(q) list = list.filter(t => (t.notes||'').toLowerCase().includes(q) || (t.category||'').toLowerCase().includes(q));
  if(filters.type) list = list.filter(t => t.type===filters.type);
  if(filters.category) list = list.filter(t => t.category===filters.category);
  if(filters.from) list = list.filter(t => new Date(t.date) >= new Date(filters.from));
  if(filters.to) list = list.filter(t => new Date(t.date) <= new Date(filters.to));

  list.sort((a,b)=>{
    const av = a[sortKey], bv = b[sortKey];
    if(sortKey==='amount') return sortDir==='asc' ? av-bv : bv-av;
    if(sortKey==='date') return sortDir==='asc' ? new Date(av)-new Date(bv) : new Date(bv)-new Date(av);
    return sortDir==='asc' ? String(av).localeCompare(String(bv)) : String(bv).localeCompare(String(av));
  });
  return list;
}

function paged(list){
  const total = list.length;
  const size = pageSize;
  const pages = Math.max(1, Math.ceil(total/size));
  currentPage = Math.min(Math.max(1, currentPage), pages);
  const start = (currentPage-1)*size;
  return { rows: list.slice(start, start+size), total, pages };
}

// ---------- Renderers ----------
function renderSummaryUI(){
  if(!incomeEl) return;
  getSummary().then(({income, expense, balance})=>{
    const cur = currencyEl?.value||'₹';
    incomeEl.textContent = cur+' '+fmt(income);
    expensesEl.textContent = cur+' '+fmt(Math.abs(expense));
    balanceEl.textContent = cur+' '+fmt(balance);
  });

  const goal = Number(localStorage.getItem('monthlyGoal')||0);
  if(goalLabel) goalLabel.textContent = goal ? ((currencyEl?.value||'₹')+' '+fmt(goal)) : 'Set';

  const monthKey = getMonthKey(new Date());
  const thisMonthExp = normalize(transactions)
    .filter(t => t.type==='expense' && getMonthKey(t.date)===monthKey)
    .reduce((s,t)=>s+Number(t.amount),0);

  const pct = goal ? Math.min(100,(thisMonthExp/goal)*100) : 0;
  if(goalProgress) goalProgress.style.width = pct.toFixed(1)+'%';
}

function renderCharts(){
  if(PAGE!=='dashboard') return;

  const byCat = {};
  normalize(transactions).forEach(t=>{
    if(t.type==='expense') byCat[t.category] = (byCat[t.category]||0)+Number(t.amount);
  });
  const catLabels = Object.keys(byCat), catData = Object.values(byCat);

  const byMonth = {};
  normalize(transactions).forEach(t=>{
    const k = getMonthKey(t.date);
    byMonth[k] = (byMonth[k]||0)+(t.type==='income'?Number(t.amount):-Number(t.amount));
  });
  const mLabels = Object.keys(byMonth).sort();
  const mData = mLabels.map(k=>byMonth[k]);

  if(window.Chart){
    if(charts.category) charts.category.destroy();
    if(charts.monthly) charts.monthly.destroy();

    const c1 = document.getElementById('categoryChart')?.getContext('2d');
    const c2 = document.getElementById('monthlyChart')?.getContext('2d');

    if(c1) charts.category = new Chart(c1, {
      type:'doughnut',
      data:{ labels:catLabels, datasets:[{ data:catData }] },
      options:{ plugins:{legend:{position:'bottom'}} }
    });

    if(c2) charts.monthly = new Chart(c2, {
      type:'line',
      data:{ labels:mLabels, datasets:[{ label:'Net', data:mData, tension:.3 }] },
      options:{ plugins:{legend:{display:false}}, scales:{ y:{beginAtZero:true} } }
    });
  }
}

function renderTable(){
  if(!tbody) return;
  const list = filtered();
  const { rows, total, pages } = paged(list);
  const cur = (currencyEl?.value)||'₹';

  tbody.innerHTML = rows.map(t=>`
    <tr>
      <td>${t.date}</td>
      <td><span class="badge ${t.type}">${t.type}</span></td>
      <td>${t.category||''}</td>
      <td>${cur} ${fmt(t.amount)}</td>
      <td>${t.notes||''}</td>
      <td>${t.recurring?'🔁':''}</td>
      <td class="row-actions">
        <button class="btn secondary" data-edit="${t.id}">Edit</button>
        <button class="btn secondary" data-del="${t.id}">Del</button>
      </td>
    </tr>
  `).join('');

  if(rowCount) rowCount.textContent = `${total} items`;
  if(pageInfo) pageInfo.textContent = `Page ${currentPage}/${pages}`;
}

function renderAll(){ renderSummaryUI(); renderTable(); renderCharts(); }
function renderCurrentPage(){ PAGE==='dashboard'?renderAll():renderTable(); }

// ---------- Modal ----------
function openModal(edit=false, data=null){
  if(!modal) return;
  modal.classList.remove('hidden');
  modalTitle.textContent = edit?'Edit Transaction':'Add Transaction';

  if(edit && data){
    editId = data.id;
    dateEl.value = data.date;
    typeEl.value = data.type;
    categoryEl.value = data.category||'Other';
    amountEl.value = data.amount;
    notesEl.value = data.notes||'';
    recurringEl.checked = !!data.recurring;
  } else {
    editId = null;
    dateEl.value = new Date().toISOString().slice(0,10);
    typeEl.value = 'expense';
    categoryEl.value = 'Food';
    amountEl.value = '';
    notesEl.value = '';
    recurringEl.checked = false;
  }
}

function closeModal(){ if(modal) modal.classList.add('hidden'); }

// ---------- Event Listeners ----------
document.addEventListener('click', async e=>{
  const editBtn = e.target.closest('button[data-edit]');
  const delBtn = e.target.closest('button[data-del]');

  if(editBtn){
    const id = editBtn.dataset.edit;
    const t = normalize(transactions).find(x=>String(x.id)===String(id));
    if(t) openModal(true, t);
  }

  if(delBtn){
    const id = delBtn.dataset.del;
    if(confirm('Delete this transaction?')){
      await deleteTxn(id);
      await refresh();
    }
  }
});

if(addBtn) addBtn.onclick = ()=>openModal(false);
if(closeModalBtn) closeModalBtn.onclick = closeModal;

if(form) form.addEventListener('submit', async e=>{
  e.preventDefault();
  const txn = {
    id: editId || cid(),
    date: dateEl.value,
    type: typeEl.value,
    category: categoryEl.value || 'Other',
    amount: Number(amountEl.value) || 0,
    notes: notesEl.value || '',
    recurring: recurringEl ? recurringEl.checked : false
  };

  // Save monthly goal if dashboard
  if(PAGE==='dashboard'){
    const goalInput = document.getElementById('goalInput');
    if(goalInput?.value) localStorage.setItem('monthlyGoal', String(goalInput.value));
  }

  if(editId) await updateTxn(editId, txn);
  else await createTxn(txn);

  closeModal();
  await refresh();
});

// ---------- Filters / Sorting / Paging ----------
if(searchEl) searchEl.oninput = ()=>{ filters.q = searchEl.value.trim(); currentPage=1; renderCurrentPage(); };
if(typeFilter) typeFilter.onchange = ()=>{ filters.type = typeFilter.value; currentPage=1; renderCurrentPage(); };
if(categoryFilter) categoryFilter.onchange = ()=>{ filters.category = categoryFilter.value; currentPage=1; renderCurrentPage(); };
if(fromDate) fromDate.onchange = ()=>{ filters.from = fromDate.value; currentPage=1; renderCurrentPage(); };
if(toDate) toDate.onchange = ()=>{ filters.to = toDate.value; currentPage=1; renderCurrentPage(); };
if(clearFilters) clearFilters.onclick = ()=>{
  filters={q:'',type:'',category:'',from:'',to:''};
  if(searchEl) searchEl.value='';
  if(typeFilter) typeFilter.value='';
  if(categoryFilter) categoryFilter.value='';
  if(fromDate) fromDate.value='';
  if(toDate) toDate.value='';
  currentPage=1;
  renderCurrentPage();
};

if(ths) ths.forEach(th=>th.addEventListener('click', ()=>{
  const key = th.dataset.sort;
  sortDir = (sortKey===key)?(sortDir==='asc'?'desc':'asc'):'asc';
  sortKey = key;
  renderCurrentPage();
}));

if(prevPage) prevPage.onclick = ()=>{ currentPage=Math.max(1,currentPage-1); renderCurrentPage(); };
if(nextPage) nextPage.onclick = ()=>{ currentPage=Math.min(Math.ceil(filtered().length/pageSize),currentPage+1); renderCurrentPage(); };
if(pageSizeEl) pageSizeEl.onchange = ()=>{ pageSize=Number(pageSizeEl.value); currentPage=1; renderCurrentPage(); };

// ---------- Export / Import ----------
if(exportJsonBtn) exportJsonBtn.onclick = ()=>download('transactions.json', JSON.stringify(transactions,null,2),'application/json');
if(exportCsvBtn) exportCsvBtn.onclick = async ()=>download('transactions.csv', await exportCsv(), 'text/csv');

if(importFile) importFile.onchange = async e=>{
  const file = e.target.files[0]; if(!file) return;
  const text = await file.text();

  if(file.name.endsWith('.json')){
    const arr = JSON.parse(text);
    for(const t of arr) await createTxn({
      id: t.id||cid(),
      date: t.date||new Date().toISOString().slice(0,10),
      type: t.type||'expense',
      category: t.category||'Other',
      amount: Math.abs(Number(t.amount)||0),
      notes: t.notes||t.description||''
    });
  } else { // CSV
    const [head,...rows] = text.trim().split(/\r?\n/);
    const cols = head.split(',').map(s=>s.trim());
    for(const r of rows){
      const vals = r.split(',').map(s=>s.trim().replace(/^"|"$/g,''));
      const obj = {}; cols.forEach((c,i)=>obj[c]=vals[i]);
      await createTxn({
        id: obj.ID||cid(),
        date: obj.Date||new Date().toISOString().slice(0,10),
        type: (Number(obj.Amount)>=0?'income':'expense'),
        category: obj.Category||'Other',
        amount: Math.abs(Number(obj.Amount)||0),
        notes: obj.Description||''
      });
    }
  }
  importFile.value='';
  await refresh();
};

// ---------- Quick Adds ----------
if(quickFood) quickFood.onclick = async ()=>{ await createTxn({id:cid(),date:new Date().toISOString().slice(0,10),type:'expense',category:'Food',amount:200,notes:'Quick add'}); refresh(); };
if(quickRent) quickRent.onclick = async ()=>{ await createTxn({id:cid(),date:new Date().toISOString().slice(0,10),type:'expense',category:'Rent',amount:10000,notes:'Quick add'}); refresh(); };
if(quickSalary) quickSalary.onclick = async ()=>{ await createTxn({id:cid(),date:new Date().toISOString().slice(0,10),type:'income',category:'Salary',amount:50000,notes:'Quick add'}); refresh(); };

// ---------- Preferences ----------
if(currencyEl) currencyEl.onchange = ()=>{ localStorage.setItem('currency',currencyEl.value); renderAll(); };
if(themeToggle) themeToggle.onclick = ()=>{ 
  const next=(localStorage.getItem('theme')==='dark')?'light':'dark'; 
  localStorage.setItem('theme',next); 
  applyTheme(next); 
};

// ---------- Init & Refresh ----------
async function refresh(){ await loadTxns(); renderCurrentPage(); }

(function init(){
  applyTheme(localStorage.getItem('theme')||'light');
  if(currencyEl) currencyEl.value = localStorage.getItem('currency')||'₹';
  if(dateEl) dateEl.value = new Date().toISOString().slice(0,10);
  refresh();
})();
