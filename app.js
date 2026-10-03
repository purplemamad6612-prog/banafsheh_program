/* Benafsheh — offline-first Persian sales & inventory workspace.
 * This UI includes demo data. Production authorization and price calculations
 * must be enforced by PocketBase rules/server code, not by browser visibility.
 */
'use strict';

const STORAGE_KEY = 'banafsheh.workspace.v1';
const TODAY = '۱۴۰۵/۰۷/۱۱';
const TODAY_LONG = 'شنبه، ۱۱ مهر ۱۴۰۵';
const faDigits = '۰۱۲۳۴۵۶۷۸۹';
const roleInfo = {
  admin: { label: 'مدیر', name: 'بنفشه احمدی', short: 'ب', pages: ['dashboard','invoices','products','customers','suppliers','inventory','cheques','investors','reports','settings'] },
  accountant: { label: 'حسابدار', name: 'سارا محسنی', short: 'س', pages: ['dashboard','invoices','customers','suppliers','cheques','investors','reports','settings'] },
  warehouse: { label: 'انباردار', name: 'رضا کریمی', short: 'ر', pages: ['dashboard','inventory','products','settings'] },
  sales: { label: 'فروشنده', name: 'علی رضایی', short: 'ع', pages: ['dashboard','invoices','products','customers','settings'] },
  investor: { label: 'سرمایه‌گذار', name: 'شرکت آریا', short: 'آ', pages: ['dashboard','investors','cheques','settings'] },
  customer: { label: 'مشتری', name: 'شرکت پنجره‌سازان آریا', short: 'پ', pages: ['dashboard','products','invoices','settings'] }
};
const navItems = [
  { id:'dashboard', label:'نمای کلی', icon:'dashboard', group:'کاربری' },
  { id:'invoices', label:'فاکتورها و پیش‌فاکتور', icon:'invoice', group:'کاربری', badge:'۳' },
  { id:'products', label:'کالاها و قیمت‌گذاری', icon:'box', group:'مدیریت' },
  { id:'customers', label:'مشتریان', icon:'users', group:'مدیریت' },
  { id:'suppliers', label:'تأمین‌کنندگان', icon:'truck', group:'مدیریت' },
  { id:'inventory', label:'انبار و گردش کالا', icon:'warehouse', group:'مدیریت' },
  { id:'cheques', label:'مدیریت چک‌ها', icon:'cheque', group:'مالی', badge:'۵' },
  { id:'investors', label:'سرمایه‌گذاران', icon:'investor', group:'مالی' },
  { id:'reports', label:'گزارش‌ها', icon:'reports', group:'مالی' },
  { id:'settings', label:'تنظیمات سیستم', icon:'settings', group:'سیستم' }
];
const pageTitles = {
  dashboard:'نمای کلی', invoices:'فاکتورها', products:'کالاها و قیمت‌گذاری', customers:'مشتریان', suppliers:'تأمین‌کنندگان',
  inventory:'انبار و گردش کالا', cheques:'مدیریت چک‌ها', investors:'سرمایه‌گذاران', reports:'گزارش‌ها', settings:'تنظیمات'
};
const icons = {
  dashboard:'<rect x="3.5" y="3.5" width="7" height="7" rx="1.6"/><rect x="13.5" y="3.5" width="7" height="4" rx="1.4"/><rect x="13.5" y="10.5" width="7" height="10" rx="1.6"/><rect x="3.5" y="13.5" width="7" height="7" rx="1.6"/>',
  invoice:'<path d="M7 3.5h7l4 4V20a1.5 1.5 0 0 1-1.5 1.5h-9A1.5 1.5 0 0 1 6 20V5a1.5 1.5 0 0 1 1-1.5Z"/><path d="M14 3.8V8h4M9 12h6M9 16h6"/>',
  box:'<path d="m12 3 8.5 4.5v9L12 21l-8.5-4.5v-9L12 3Z"/><path d="m3.8 7.7 8.2 4.4 8.2-4.4M12 12.2V21M7.5 5.4l8.3 4.5"/>',
  users:'<path d="M16 20v-1.8a3.2 3.2 0 0 0-3.2-3.2H6.2A3.2 3.2 0 0 0 3 18.2V20"/><circle cx="9.5" cy="8" r="3.5"/><path d="M17 11a3.5 3.5 0 0 0 0-6.8M21 20v-1.8a3.2 3.2 0 0 0-2.5-3.1"/>',
  warehouse:'<path d="m3 10 9-6 9 6v10.5a.5.5 0 0 1-.5.5h-17a.5.5 0 0 1-.5-.5V10Z"/><path d="M8 21v-6h8v6M7.5 11h.01M12 11h.01M16.5 11h.01"/>',
  cheque:'<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 10h18M7 15h4M16 15h1"/>',
  investor:'<path d="M4 17.5 9 12l3 3 7-8"/><path d="M14 7h5v5M4 21h16"/><circle cx="6" cy="7" r="2"/>',
  reports:'<path d="M4 19V5M4 19h17"/><rect x="7" y="11" width="3" height="5" rx=".7"/><rect x="13" y="7" width="3" height="9" rx=".7"/><rect x="19" y="4" width="2" height="12" rx=".7"/>',
  settings:'<circle cx="12" cy="12" r="3"/><path d="m19.4 15 .1.1 1.2.9-1.5 2.6-1.4-.6a7.5 7.5 0 0 1-1.7 1l-.2 1.5h-3l-.3-1.5a7.5 7.5 0 0 1-1.7-1l-1.4.6-1.5-2.6 1.2-.9a7 7 0 0 1 0-2l-1.2-.9 1.5-2.6 1.4.6a7.5 7.5 0 0 1 1.7-1l.3-1.5h3l.2 1.5a7.5 7.5 0 0 1 1.7 1l1.4-.6 1.5 2.6-1.2.9a7 7 0 0 1 0 2Z" transform="translate(-1 -1) scale(1.08)"/>',
  search:'<circle cx="10.8" cy="10.8" r="6.7"/><path d="m16 16 4.2 4.2"/>',
  calendar:'<rect x="3.5" y="5" width="17" height="16" rx="2"/><path d="M7.5 3v4M16.5 3v4M3.5 9h17M8 13h.01M12 13h.01M16 13h.01M8 17h.01M12 17h.01"/>',
  bell:'<path d="M18 9a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9ZM10 21h4"/>',
  chevronDown:'<path d="m7 10 5 5 5-5"/>',
  chevronLeft:'<path d="m14 6-6 6 6 6"/>',
  menu:'<path d="M4 6h16M4 12h16M4 18h16"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  arrowUp:'<path d="m7 14 5-5 5 5"/>',
  arrowDown:'<path d="m7 10 5 5 5-5"/>',
  wallet:'<path d="M4 6.5h15a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6.5a2 2 0 0 1 2-2h13"/><path d="M17 13h4M6 4h11"/><circle cx="17" cy="13" r=".7"/>',
  percent:'<path d="M19 5 5 19"/><circle cx="7" cy="7" r="2.2"/><circle cx="17" cy="17" r="2.2"/>',
  clipboard:'<rect x="5" y="4" width="14" height="17" rx="2"/><path d="M9 4.5v-1h6v1M8.5 10h7M8.5 14h7M8.5 18h4"/>',
  arrowLeft:'<path d="M19 12H5M12 19l-7-7 7-7"/>',
  trend:'<path d="m4 16 6-6 4 4 6-8"/><path d="M14 6h6v6"/>',
  eye:'<path d="M2.5 12s3.2-6 9.5-6 9.5 6 9.5 6-3.2 6-9.5 6-9.5-6-9.5-6Z"/><circle cx="12" cy="12" r="2.5"/>',
  edit:'<path d="m4 16.5-.8 4.3 4.3-.8L19 8.5 15.5 5 4 16.5Z"/><path d="m13.5 7 3.5 3.5"/>',
  trash:'<path d="M4 7h16M10 11v6M14 11v6M5.5 7l1 14h11l1-14M9 7V4h6v3"/>',
  close:'<path d="m6 6 12 12M18 6 6 18"/>',
  check:'<path d="m5 12 4.5 4.5L19 7"/>',
  sync:'<path d="M20 7v5h-5M4 17v-5h5"/><path d="M5.6 9a7 7 0 0 1 11.7-2.2L20 12M4 12l2.7 5.2A7 7 0 0 0 18.4 15"/>',
  wifi:'<path d="M3 9a14 14 0 0 1 18 0M6 12a9.5 9.5 0 0 1 12 0M9.5 15.5a4.2 4.2 0 0 1 5 0M12 19h.01"/>',
  truck:'<path d="M3 6h11v11H3zM14 10h4l3 3v4h-7"/><circle cx="7" cy="19" r="2"/><circle cx="18" cy="19" r="2"/>',
  upload:'<path d="M12 16V4M7 9l5-5 5 5M4 20h16"/>',
  download:'<path d="M12 4v12M7 11l5 5 5-5M4 20h16"/>',
  logout:'<path d="M10 17l5-5-5-5M15 12H3"/><path d="M12 3h6a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-6"/>',
  shield:'<path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11Z"/><path d="m9 12 2 2 4-4"/>',
  printer:'<path d="M6 9V3h12v6M6 17H4a2 2 0 0 1-2-2v-4a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v4a2 2 0 0 1-2 2h-2"/><path d="M6 14h12v7H6zM18 12h.01"/>',
  filter:'<path d="M4 6h16M7 12h10M10 18h4"/>',
  clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
  alert:'<path d="M10.3 4.3 2.8 17.5A2 2 0 0 0 4.5 20.5h15a2 2 0 0 0 1.7-3L13.7 4.3a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4M12 17h.01"/>',
  transfer:'<path d="M7 7h13l-3-3M17 17H4l3 3"/><path d="M20 7v3M4 17v-3"/>',
  money:'<path d="M3 7.5h18v12H3zM3 10l8-6 10 6"/><circle cx="12" cy="13.5" r="2.5"/>',
  bag:'<path d="M5 8h14l1 12H4L5 8Z"/><path d="M9 8V6a3 3 0 0 1 6 0v2M9 12v.01M15 12v.01"/>',
  pin:'<path d="M20 10c0 5-8 12-8 12S4 15 4 10a8 8 0 1 1 16 0Z"/><circle cx="12" cy="10" r="2.5"/>',
  more:'<circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/>',
  boxSearch:'<path d="m12 3 8 4.3v8.4L12 20l-8-4.3V7.3L12 3Z"/><path d="m4.3 7.5 7.7 4.2 7.7-4.2M12 11.7V20M16.5 16.5l4 4M18.5 14.5a2.5 2.5 0 1 0 0 .01"/>',
  fileDown:'<path d="M7 3.5h7l4 4v13H7a2 2 0 0 1-2-2v-13a2 2 0 0 1 2-2Z"/><path d="M14 3.8V8h4M12 11v6M9.5 14.5 12 17l2.5-2.5"/>',
  help:'<circle cx="12" cy="12" r="9"/><path d="M9.5 9a2.5 2.5 0 1 1 4.4 1.6c-1 .9-1.9 1.3-1.9 2.9M12 17h.01"/>'
};

const initialData = {
  role: 'admin', activePage: 'dashboard', loggedIn: true,
  settings: { pbUrl: '', lastSync: '۱۴۰۵/۰۷/۱۱، ۰۹:۳۲', taxRate: 0, offlineMode: true },
  warehouses: [
    { id:'wh-01', name:'انبار مرکزی', location:'تهران، جاده مخصوص', stockValue: 8650, percent:72 },
    { id:'wh-02', name:'انبار شعبه غرب', location:'تهران، شهرک غرب', stockValue: 2930, percent:48 },
    { id:'wh-03', name:'انبار شوروم', location:'تهران، ستارخان', stockValue: 1140, percent:35 }
  ],
  products: [
    { id:'p-01', code:'PR-060-GD', name:'پروفیل ۶۰ گلدویین', group:'پروفیل فریم', baseUnit:'شاخه', stockBase:876, minStock:180, baseCost:1450000, baseSell:1770000, adjustment:0, warehouse:'انبار مرکزی', color:'purple', units:[{name:'شاخه',factor:1},{name:'متر',factor:.1667},{name:'بسته',factor:25,version:2}] },
    { id:'p-02', code:'PR-070-WH', name:'پروفیل ۷۰ سفید', group:'پروفیل فریم', baseUnit:'شاخه', stockBase:93, minStock:120, baseCost:1820000, baseSell:2220000, adjustment:0, warehouse:'انبار مرکزی', color:'blue', units:[{name:'شاخه',factor:1},{name:'متر',factor:.1667},{name:'بسته',factor:20,version:1}] },
    { id:'p-03', code:'GL-4-CLR', name:'شیشه دوجداره ۴ میل', group:'شیشه و ملزومات', baseUnit:'مترمربع', stockBase:62, minStock:50, baseCost:1180000, baseSell:1439000, adjustment:0, warehouse:'انبار شعبه غرب', color:'teal', units:[{name:'مترمربع',factor:1},{name:'ورق',factor:4.5}] },
    { id:'p-04', code:'HW-HNG-3D', name:'لولا سه‌بعدی ترک', group:'یراق‌آلات', baseUnit:'عدد', stockBase:44, minStock:60, baseCost:290000, baseSell:354000, adjustment:0, warehouse:'انبار مرکزی', color:'orange', units:[{name:'عدد',factor:1},{name:'بسته',factor:10}] },
    { id:'p-05', code:'PR-050-WH', name:'پروفیل ۵۰ سفید', group:'پروفیل فریم', baseUnit:'شاخه', stockBase:384, minStock:100, baseCost:1120000, baseSell:1366000, adjustment:0, warehouse:'انبار مرکزی', color:'purple', units:[{name:'شاخه',factor:1},{name:'متر',factor:.1667},{name:'بسته',factor:25}] },
    { id:'p-06', code:'GSK-EPDM', name:'لاستیک EPDM مشکی', group:'نوار و لاستیک', baseUnit:'کیلو', stockBase:176, minStock:80, baseCost:375000, baseSell:458000, adjustment:0, warehouse:'انبار شعبه غرب', color:'teal', units:[{name:'کیلو',factor:1},{name:'کلاف',factor:15}] },
    { id:'p-07', code:'HW-LOCK-2P', name:'قفل دو زبانه پنجره', group:'یراق‌آلات', baseUnit:'عدد', stockBase:112, minStock:45, baseCost:640000, baseSell:781000, adjustment:0, warehouse:'انبار مرکزی', color:'orange', units:[{name:'عدد',factor:1},{name:'بسته',factor:5}] },
    { id:'p-08', code:'PR-ARCH-60', name:'پروفیل لنگه ۶۰', group:'پروفیل لنگه', baseUnit:'شاخه', stockBase:58, minStock:90, baseCost:1560000, baseSell:1903000, adjustment:0, warehouse:'انبار شوروم', color:'blue', units:[{name:'شاخه',factor:1},{name:'متر',factor:.1667},{name:'بسته',factor:20}] }
  ],
  customers: [
    { id:'c-01', code:'C-1042', name:'شرکت پنجره‌سازان آریا', phone:'۰۲۱-۴۴۴۲۱۲۸۰', type:'عمده', group:'همکاران ویژه', adjustment:-2, balance:36800000, limit:250000000, city:'تهران', active:true },
    { id:'c-02', code:'C-1088', name:'فروشگاه خانه مدرن', phone:'۰۲۱-۸۸۴۳۱۰۲۴', type:'عمده', group:'همکاران', adjustment:-1, balance:12850000, limit:120000000, city:'تهران', active:true },
    { id:'c-03', code:'C-1116', name:'آقای محمد امینی', phone:'۰۹۱۲۷۳۸۴۱۵۰', type:'خرده', group:'خرده‌فروشی', adjustment:0, balance:0, limit:30000000, city:'کرج', active:true },
    { id:'c-04', code:'C-1129', name:'تولیدی درب و پنجره سپهر', phone:'۰۲۶-۳۲۷۵۱۰۹۲', type:'عمده', group:'همکاران ویژه', adjustment:-2, balance:74500000, limit:300000000, city:'کرج', active:true },
    { id:'c-05', code:'C-1180', name:'پروژه مسکونی پارک وی', phone:'۰۹۱۲۲۱۵۹۰۳۳', type:'متفرقه', group:'پروژه‌ای', adjustment:-3, balance:26400000, limit:180000000, city:'تهران', active:true },
    { id:'c-06', code:'C-1203', name:'فروشگاه یراق پایدار', phone:'۰۲۱-۶۶۱۰۹۵۷۲', type:'عمده', group:'همکاران', adjustment:-1, balance:9200000, limit:80000000, city:'تهران', active:true }
  ],
  suppliers: [
    { id:'s-01', code:'S-001', name:'بازرگانی آذر پروفیل', phone:'۰۲۱-۶۶۱۲۸۳۹۰', address:'تهران، شهرک صنعتی غرب', balance:124800000, notes:'تأمین پروفیل فریم و لنگه' },
    { id:'s-02', code:'S-002', name:'یراق‌آلات آریا', phone:'۰۲۱-۵۵۶۷۳۲۱۸', address:'تهران، بازار آهن', balance:38700000, notes:'تأمین انواع یراق' },
    { id:'s-03', code:'S-003', name:'شیشه‌سازی سپنتا', phone:'۰۲۶-۳۲۵۴۱۰۷۰', address:'کرج، جاده مخصوص', balance:61200000, notes:'شیشه دوجداره و تک‌جداره' }
  ],
  invoices: [
    { id:'i-01', number:'۱۴۰۵-۰۰۸۲', type:'فروش', customerId:'c-01', customerName:'شرکت پنجره‌سازان آریا', date:'۱۴۰۵/۰۷/۱۱', mode:'نقدی', status:'confirmed', itemCount:4, subtotal:23850000, discount:477000, surcharge:0, total:23373000, note:'ارسال با خودروی مشتری', items:[] },
    { id:'i-02', number:'۱۴۰۵-۰۰۸۱', type:'فروش', customerId:'c-04', customerName:'تولیدی درب و پنجره سپهر', date:'۱۴۰۵/۰۷/۱۱', mode:'چک مستقیم', status:'confirmed', itemCount:7, subtotal:46200000, discount:0, surcharge:924000, total:47124000, note:'', items:[] },
    { id:'i-03', number:'۱۴۰۵-۰۰۸۰', type:'پیش‌فاکتور', customerId:'c-02', customerName:'فروشگاه خانه مدرن', date:'۱۴۰۵/۰۷/۱۰', mode:'نقدی', status:'draft', itemCount:3, subtotal:18600000, discount:186000, surcharge:0, total:18414000, note:'اعتبار تا ۳ روز', items:[] },
    { id:'i-04', number:'۱۴۰۵-۰۰۷۹', type:'فروش', customerId:'c-05', customerName:'پروژه مسکونی پارک وی', date:'۱۴۰۵/۰۷/۱۰', mode:'سرمایه‌گذار', status:'confirmed', itemCount:6, subtotal:56200000, discount:0, surcharge:1686000, total:57886000, note:'', items:[] },
    { id:'i-05', number:'۱۴۰۵-۰۰۷۸', type:'فروش', customerId:'c-03', customerName:'آقای محمد امینی', date:'۱۴۰۵/۰۷/۰۹', mode:'نقدی', status:'confirmed', itemCount:2, subtotal:9650000, discount:0, surcharge:0, total:9650000, note:'تحویل از شوروم', items:[] },
    { id:'i-06', number:'۱۴۰۵-۰۰۷۷', type:'خرید', customerId:'supplier-01', customerName:'بازرگانی آذر پروفیل', date:'۱۴۰۵/۰۷/۰۸', mode:'پرداخت مدت‌دار', status:'confirmed', itemCount:12, subtotal:78500000, discount:0, surcharge:0, total:78500000, note:'', items:[] },
    { id:'i-07', number:'۱۴۰۵-۰۰۷۶', type:'پیش‌فاکتور', customerId:'c-06', customerName:'فروشگاه یراق پایدار', date:'۱۴۰۵/۰۷/۰۸', mode:'چک مستقیم', status:'draft', itemCount:5, subtotal:12750000, discount:0, surcharge:255000, total:13005000, note:'', items:[] }
  ],
  cheques: [
    { id:'ch-01', number:'۶۲۴۸۳۱', bank:'ملت', amount:32500000, party:'شرکت پنجره‌سازان آریا', type:'دریافتی', due:'۱۴۰۵/۰۷/۱۳', status:'in_hand', holder:'بنفشه' },
    { id:'ch-02', number:'۹۱۸۳۲۷', bank:'تجارت', amount:18400000, party:'تولیدی سپهر', type:'دریافتی', due:'۱۴۰۵/۰۷/۱۵', status:'deposited', holder:'بنفشه' },
    { id:'ch-03', number:'۴۵۰۱۹۲', bank:'صادرات', amount:46700000, party:'بازرگانی آذر پروفیل', type:'پرداختی', due:'۱۴۰۵/۰۷/۱۸', status:'in_hand', holder:'بنفشه' },
    { id:'ch-04', number:'۷۲۰۵۵۱', bank:'سامان', amount:12700000, party:'پروژه مسکونی پارک وی', type:'دریافتی', due:'۱۴۰۵/۰۷/۲۰', status:'transferred', holder:'سرمایه‌گذار', investorId:'inv-01' },
    { id:'ch-05', number:'۸۳۱۶۰۲', bank:'ملت', amount:9600000, party:'فروشگاه خانه مدرن', type:'دریافتی', due:'۱۴۰۵/۰۷/۰۹', status:'bounced', holder:'بنفشه' },
    { id:'ch-06', number:'۶۱۰۴۹۸', bank:'پارسیان', amount:25800000, party:'تأمین‌کننده یراق آریا', type:'پرداختی', due:'۱۴۰۵/۰۷/۲۵', status:'in_hand', holder:'بنفشه' }
  ],
  investors: [
    { id:'inv-01', name:'شرکت سرمایه‌گذاری آریا', phone:'۰۲۱-۸۸۷۳۲۱۱۰', active:true },
    { id:'inv-02', name:'آقای فرهاد موسوی', phone:'۰۹۱۲۴۵۳۸۱۲۰', active:true },
    { id:'inv-03', name:'گروه بازرگانی کاوه', phone:'۰۲۱-۶۶۵۱۰۲۷۰', active:true }
  ],
  deals: [
    { id:'d-01', investorId:'inv-01', investor:'شرکت سرمایه‌گذاری آریا', customer:'پروژه مسکونی پارک وی', date:'۱۴۰۵/۰۷/۱۰', companyPrice:51200000, customerPrice:57886000, investorProfit:6686000, companyCost:46300000, status:'open', chequeCount:1 },
    { id:'d-02', investorId:'inv-02', investor:'آقای فرهاد موسوی', customer:'تولیدی پنجره آفتاب', date:'۱۴۰۵/۰۷/۰۸', companyPrice:33800000, customerPrice:37400000, investorProfit:3600000, companyCost:30600000, status:'settled', chequeCount:1 },
    { id:'d-03', investorId:'inv-01', investor:'شرکت سرمایه‌گذاری آریا', customer:'مجتمع تجاری آسمان', date:'۱۴۰۵/۰۷/۰۶', companyPrice:42600000, customerPrice:47200000, investorProfit:4600000, companyCost:38900000, status:'open', chequeCount:2 },
    { id:'d-04', investorId:'inv-03', investor:'گروه بازرگانی کاوه', customer:'فروشگاه خانه مدرن', date:'۱۴۰۵/۰۷/۰۵', companyPrice:28900000, customerPrice:32100000, investorProfit:3200000, companyCost:26300000, status:'open', chequeCount:1 }
  ],
  movements: [
    { id:'m-01', syncId:'seed-001', productId:'p-01', productName:'پروفیل ۶۰ گلدویین', warehouse:'انبار مرکزی', type:'sale_out', quantityBase:25, unit:'شاخه', quantity:25, factor:1, date:'۱۴۰۵/۰۷/۱۱', user:'رضا کریمی', reference:'۱۴۰۵-۰۰۸۲', synced:true },
    { id:'m-02', syncId:'seed-002', productId:'p-06', productName:'لاستیک EPDM مشکی', warehouse:'انبار شعبه غرب', type:'purchase_in', quantityBase:45, unit:'کیلو', quantity:45, factor:1, date:'۱۴۰۵/۰۷/۱۱', user:'رضا کریمی', reference:'رسید ۲۱۸', synced:true },
    { id:'m-03', syncId:'seed-003', productId:'p-04', productName:'لولا سه‌بعدی ترک', warehouse:'انبار مرکزی', type:'transfer_out', quantityBase:12, unit:'عدد', quantity:12, factor:1, date:'۱۴۰۵/۰۷/۱۰', user:'رضا کریمی', reference:'انتقال ۰۴۱', synced:true },
    { id:'m-04', syncId:'seed-004', productId:'p-02', productName:'پروفیل ۷۰ سفید', warehouse:'انبار مرکزی', type:'sale_out', quantityBase:8, unit:'شاخه', quantity:8, factor:1, date:'۱۴۰۵/۰۷/۱۰', user:'رضا کریمی', reference:'۱۴۰۵-۰۰۸۰', synced:true }
  ],
  syncQueue: [], nextInvoice: 83
};

function clone(obj) { return JSON.parse(JSON.stringify(obj)); }
function loadData() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || 'null');
    if (!saved || !saved.products || !saved.customers) return clone(initialData);
    const base = clone(initialData);
    return { ...base, ...saved, settings:{...base.settings,...(saved.settings || {})} };
  } catch { return clone(initialData); }
}
let db = loadData();
let currentInvoiceFilter = 'all';
let currentProductGroup = 'همه کالاها';
let globalSearch = '';
let activeToastTimer;

function saveData() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(db)); }
  catch (err) { console.warn('Local save failed', err); }
}
function faNum(value) {
  return String(value).replace(/\d/g, d => faDigits[Number(d)]);
}
function numberString(value) {
  const num = Number(value) || 0;
  const fixed = Number.isInteger(num) ? String(num) : String(Number(num.toFixed(3)));
  const parts = fixed.split('.');
  parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, '٬');
  return faNum(parts.join('.'));
}
function toman(value, includeUnit = true) {
  const output = numberString(Math.round(Number(value) || 0));
  return includeUnit ? `${output} تومان` : output;
}
function esc(value) {
  return String(value ?? '').replace(/[&<>"']/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
}
function icon(name, size = 19) {
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${icons[name] || icons.box}</svg>`;
}
function shortName(name) { return String(name || '').trim().slice(0, 1); }
function activeRole() { const role=roleInfo[db.role]||roleInfo.admin; return db.serverUserName?{...role,name:db.serverUserName}:role; }
function canSeeCost() { return db.role === 'admin'; }
function canSeeMoney() { return db.role !== 'warehouse'; }
function pageAllowed(page) { return activeRole().pages.includes(page); }
function ensureAllowedPage() { if (!pageAllowed(db.activePage)) db.activePage = 'dashboard'; }
function customerById(id) { return db.customers.find(c => c.id === id); }
function productById(id) { return db.products.find(p => p.id === id); }
function investorById(id) { return db.investors.find(i => i.id === id); }
function percentageOfToman(amount, percent) {
  const integer=Math.round(Number(amount)||0);
  const basisPoints=Math.round((Number(percent)||0)*100);
  const whole=Math.floor(integer/10000);
  const remainder=integer-whole*10000;
  return whole*basisPoints+Math.round(remainder*basisPoints/10000);
}
function applyTomanPercent(amount, percent) { return Math.round(Number(amount)||0)+percentageOfToman(amount,percent); }
function multiplyTomanByFactor(amount, factor) {
  const integer=Math.round(Number(amount)||0);
  const scaledFactor=Math.max(0,Math.round((Number(factor)||0)*1000000));
  const whole=Math.floor(integer/1000000);
  const remainder=integer-whole*1000000;
  return whole*scaledFactor+Math.round(remainder*scaledFactor/1000000);
}
function divideTomanByFactor(amount, factor) {
  const integer=Math.round(Number(amount)||0);
  const scaledFactor=Math.max(1,Math.round((Number(factor)||0)*1000000));
  const whole=Math.floor(integer/scaledFactor);
  const remainder=integer-whole*scaledFactor;
  return whole*1000000+Math.round(remainder*1000000/scaledFactor);
}
function lineTomanTotal(unitPrice, quantity) {
  const quantityMilli=Math.max(0,Math.round((Number(quantity)||0)*1000));
  const whole=Math.floor(quantityMilli/1000);
  const remainder=quantityMilli-whole*1000;
  return whole*Math.round(Number(unitPrice)||0)+Math.round(remainder*Math.round(Number(unitPrice)||0)/1000);
}
function roundedPrice(value, rule = 'nearest_1000') {
  const step = rule === 'nearest_10000' ? 10000 : rule === 'nearest_5000' ? 5000 : rule === 'none' ? 1 : 1000;
  const integer=Math.round(Number(value)||0);
  const quotient=Math.floor(integer/step);
  const remainder=integer-quotient*step;
  return (remainder>=Math.ceil(step/2)?quotient+1:quotient)*step;
}
function priceGroupAdjustment(customerId) {
  const customer = customerById(customerId);
  return customer ? Number(customer.adjustment || 0) : 0;
}
function activeUnit(product, name) { return product?.units?.find(u => u.name === name) || product?.units?.[0] || { name:product?.baseUnit || 'عدد', factor:1 }; }
function stockText(product) {
  if (!product) return '—';
  const pack = [...(product.units || [])].filter(u => u.factor > 1).sort((a,b) => b.factor-a.factor)[0];
  if (!pack) return `${numberString(product.stockBase)} ${product.baseUnit}`;
  const packs = Math.floor(product.stockBase / pack.factor);
  const remain = Number((product.stockBase - packs * pack.factor).toFixed(3));
  return remain ? `${numberString(packs)} ${pack.name} + ${numberString(remain)} ${product.baseUnit}` : `${numberString(packs)} ${pack.name}`;
}
function statusLabel(status) {
  const names = { confirmed:'تأیید شده', draft:'پیش‌نویس', cancelled:'لغو شده', in_hand:'در دست', deposited:'واگذار به بانک', cleared:'وصول شده', bounced:'برگشتی', transferred:'واگذار شده', open:'باز', settled:'تسویه شده', active:'فعال', pending:'در انتظار' };
  return names[status] || status;
}
function statusClass(status) { return status || 'pending'; }
function modeLabel(mode) { return ({cash:'نقدی',cheque_direct:'چک مستقیم',investor:'سرمایه‌گذار', 'نقدی':'نقدی','چک مستقیم':'چک مستقیم','سرمایه‌گذار':'سرمایه‌گذار'}[mode] || mode || '—'); }
function typeLabel(type) { return ({wholesale:'عمده',retail:'خرده',misc:'متفرقه'}[type] || type); }
function pageHead(title, sub, actions = '') {
  return `<div class="page-heading"><div><h1>${title}</h1><p>${sub || ''}</p></div><div class="heading-actions">${actions}</div></div>`;
}
function actionButton(action, label, iconName = 'plus', style = 'btn-primary', extra = '') {
  return `<button class="btn ${style} ${extra}" data-action="${action}">${icon(iconName,15)}<span>${label}</span></button>`;
}
function renderApp() {
  if (!db.loggedIn) { renderLogin(); return; }
  ensureAllowedPage();
  const root = document.getElementById('app');
  const role = activeRole();
  const title = pageTitles[db.activePage] || 'نمای کلی';
  root.innerHTML = `
    <div class="app-shell">
      <aside class="sidebar" id="sidebar">
        <div class="brand"><div class="brand-mark"><svg viewBox="0 0 32 32" fill="none" aria-hidden="true"><path d="M7 25V7h10.2c5.2 0 8.3 2.6 8.3 6.6 0 2.4-1.2 4.2-3.6 5.1L27 25h-7l-4.4-5.4h-2.5V25H7Zm6.1-10h3.8c1.6 0 2.5-.5 2.5-1.5S18.5 12 16.9 12h-3.8v3Z" fill="currentColor"/></svg></div><div><div class="brand-name">بنفشه</div><div class="brand-sub">مدیریت فروش و انبار</div></div></div>
        <div class="sidebar-label">منوی اصلی</div>
        <nav class="nav-list">${renderNav()}</nav>
        <div class="sidebar-spacer"></div>
        <div class="sync-card"><div class="sync-top"><span class="sync-dot ${navigator.onLine ? 'online' : ''}"></span><span>${navigator.onLine ? 'حالت آنلاین' : 'حالت آفلاین'}</span><span class="nav-count">${faNum(db.syncQueue.length)}</span></div><div class="sync-detail">آخرین همگام‌سازی: ${esc(db.settings.lastSync || 'هنوز انجام نشده')}</div></div>
        <div class="sidebar-user"><div class="avatar">${esc(role.short)}</div><div class="user-meta"><div class="user-name">${esc(role.name)}</div><div class="user-role">${esc(role.label)}</div></div><button aria-label="خروج" data-action="logout">${icon('logout',16)}</button></div>
      </aside>
      <div class="sidebar-overlay" id="sidebarOverlay"></div>
      <main class="main-panel">
        <header class="topbar">
          <button class="mobile-menu" data-action="toggle-menu" aria-label="باز کردن منو">${icon('menu',18)}</button>
          <div class="topbar-page"><strong>${esc(title)}</strong><span>سامانه یکپارچه بنفشه</span></div>
          <div class="topbar-tools">
            <label class="search-box">${icon('search',17)}<input id="global-search" type="search" placeholder="جستجو در بنفشه..." value="${esc(globalSearch)}" aria-label="جستجو" /></label>
            <div class="date-pill">${icon('calendar',15)}<span>${TODAY_LONG}</span></div>
            <button class="icon-button" data-action="alerts" aria-label="اعلان‌ها">${icon('bell',17)}<span class="notification-dot"></span></button>
            <button class="top-profile" data-action="open-role" aria-label="تغییر نقش"><span class="avatar">${esc(role.short)}</span><span class="top-profile-text"><strong>${esc(role.name)}</strong><span>${esc(role.label)}</span></span>${icon('chevronDown',14)}</button>
          </div>
        </header>
        <div class="page-wrap">${renderPage()}</div>
      </main>
      ${renderMobileNav()}
    </div>`;
  document.title = `${title} | بنفشه`;
  bindPwa();
}
function renderNav() {
  let lastGroup = '';
  return navItems.filter(item => pageAllowed(item.id)).map(item => {
    let label = '';
    if (item.group !== lastGroup && item.id !== 'dashboard') { label = `<div class="sidebar-label">${item.group === 'مدیریت' ? 'اطلاعات پایه' : item.group === 'مالی' ? 'امور مالی' : 'سیستم'}</div>`; }
    lastGroup = item.group;
    const isActive = db.activePage === item.id;
    const badge = item.badge && (item.id === 'cheques' || item.id === 'invoices') ? `<span class="nav-count">${item.id === 'cheques' ? faNum(db.cheques.filter(c=>['in_hand','bounced'].includes(c.status)).length) : faNum(db.invoices.filter(i=>i.status==='draft').length)}</span>` : '';
    return `${label}<button class="nav-link ${isActive?'active':''}" data-nav="${item.id}">${icon(item.icon,19)}<span>${item.label}</span>${badge}</button>`;
  }).join('');
}
function renderMobileNav() {
  const preferred = ['dashboard','invoices','products','inventory','customers','cheques','investors'];
  const items = preferred.filter(id => pageAllowed(id)).slice(0,4);
  return `<nav class="mobile-bottom-nav">${items.map(id => { const item=navItems.find(n=>n.id===id);return `<button class="mobile-nav-item ${db.activePage===id?'active':''}" data-nav="${id}">${icon(item.icon,19)}<span>${id==='dashboard'?'خانه':item.label.split(' ')[0]}</span></button>`; }).join('')}</nav>`;
}
function renderPage() {
  switch (db.activePage) {
    case 'invoices': return renderInvoices();
    case 'products': return renderProducts();
    case 'customers': return renderCustomers();
    case 'suppliers': return renderSuppliers();
    case 'inventory': return renderInventory();
    case 'cheques': return renderCheques();
    case 'investors': return renderInvestors();
    case 'reports': return renderReports();
    case 'settings': return renderSettings();
    default: return renderDashboard();
  }
}
function renderKpi({label,value,unit='',color='purple',iconName='wallet',foot='',spark='up'}) {
  const sparkPath = spark === 'down' ? 'M2 7 C10 6 13 19 22 16 S38 6 46 10 S61 21 72 13' : 'M2 21 C11 17 12 18 21 14 S32 17 40 11 S57 13 72 4';
  return `<div class="card kpi-card"><div class="kpi-top"><div><div class="kpi-label">${label}</div><div class="kpi-value">${value}${unit?`<span class="kpi-unit">${unit}</span>`:''}</div><div class="kpi-foot">${foot}</div></div><div class="kpi-icon ${color}">${icon(iconName,18)}</div></div><svg class="kpi-spark" viewBox="0 0 74 28" fill="none"><path d="${sparkPath}" stroke="${spark==='down'?'#e8959d':'#8a81ed'}" stroke-width="2" stroke-linecap="round"/></svg></div>`;
}
function renderAdminDashboard() {
  const canMoney = canSeeMoney();
  const kpis = db.role === 'warehouse' ? [
    {label:'موجودی کالاها',value:faNum(db.products.length),unit:'قلم',color:'purple',iconName:'box',foot:'در ۳ انبار فعال'},
    {label:'گردش امروز',value:faNum(db.movements.filter(m=>m.date===TODAY).length+7),unit:'سند',color:'teal',iconName:'transfer',foot:'ورود، خروج و انتقال'},
    {label:'کالاهای کم‌موجود',value:faNum(db.products.filter(p=>p.stockBase<=p.minStock).length),unit:'قلم',color:'orange',iconName:'alert',foot:'نیازمند بررسی'},
    {label:'در صف همگام‌سازی',value:faNum(db.syncQueue.length),unit:'سند',color:'blue',iconName:'sync',foot:'ذخیره‌شده روی دستگاه'}
  ] : db.role === 'accountant' ? [
    {label:'دریافت امروز',value:'۴۸٫۲',unit:'میلیون تومان',color:'teal',iconName:'wallet',foot:'۱۲٪ بیشتر از دیروز'},
    {label:'مانده مطالبات',value:'۲۸۶٫۴',unit:'میلیون تومان',color:'purple',iconName:'users',foot:'از ۱۸ مشتری فعال'},
    {label:'چک‌های سررسید',value:'۵',unit:'فقره',color:'orange',iconName:'cheque',foot:'در ۷ روز آینده'},
    {label:'مانده پرداختنی',value:'۱۲۴٫۸',unit:'میلیون تومان',color:'blue',iconName:'money',foot:'به ۶ تأمین‌کننده'}
  ] : db.role === 'sales' ? [
    {label:'فروش امروز',value:'۸۴٫۵',unit:'میلیون تومان',color:'purple',iconName:'wallet',foot:'۱۲٫۸٪ رشد نسبت به دیروز'},
    {label:'فاکتورهای امروز',value:'۲۴',unit:'فقره',color:'teal',iconName:'invoice',foot:'۳ پیش‌فاکتور باز'},
    {label:'مشتریان امروز',value:'۱۸',unit:'مشتری',color:'orange',iconName:'users',foot:'۶ مشتری جدید'},
    {label:'سفارش‌های باز',value:'۷',unit:'سفارش',color:'blue',iconName:'bag',foot:'نیازمند پیگیری'}
  ] : db.role === 'customer' ? [
    {label:'مانده حساب شما',value:'۳۶٫۸',unit:'میلیون تومان',color:'purple',iconName:'wallet',foot:'مهلت پرداخت تا ۲۰ مهر'},
    {label:'فاکتورهای این ماه',value:'۸',unit:'فقره',color:'teal',iconName:'invoice',foot:'۲ فاکتور پرداخت‌نشده'},
    {label:'چک‌های ثبت‌شده',value:'۲',unit:'فقره',color:'orange',iconName:'cheque',foot:'آخرین سررسید ۱۵ مهر'},
    {label:'سفارش‌های جاری',value:'۱',unit:'سفارش',color:'blue',iconName:'box',foot:'در حال آماده‌سازی'}
  ] : [
    {label:'فروش امروز',value:'۸۴٫۵',unit:'میلیون تومان',color:'purple',iconName:'wallet',foot:'۱۲٫۸٪ رشد نسبت به دیروز'},
    {label:'فاکتورهای امروز',value:'۲۴',unit:'فقره',color:'teal',iconName:'invoice',foot:'۳ پیش‌فاکتور باز'},
    {label:'مطالبات باز',value:'۲۸۶٫۴',unit:'میلیون تومان',color:'orange',iconName:'users',foot:'از ۱۸ مشتری فعال'},
    {label:'سود خالص',value:'۱۸٫۷',unit:'میلیون تومان',color:'blue',iconName:'trend',foot:'۸٫۲٪ نسبت به هفته قبل'}
  ];
  const recent = db.role === 'customer' ? db.invoices.filter(i=>i.customerId==='c-01').slice(0,5) : db.invoices.filter(i=>i.type==='فروش' || i.type==='پیش‌فاکتور').slice(0,5);
  const lowStock = [...db.products].sort((a,b)=>(a.stockBase/a.minStock)-(b.stockBase/b.minStock)).slice(0,4);
  const chartTitle = db.role === 'customer' ? 'خریدهای شما' : db.role === 'warehouse' ? 'گردش موجودی' : db.role === 'accountant' ? 'جریان نقدی' : 'روند فروش';
  const chartAmount = db.role === 'warehouse' ? '۱٬۲۸۶' : db.role === 'customer' ? '۳۱۲٫۸ میلیون تومان' : '۸۴٫۵ میلیون تومان';
  const recentPanel = db.role === 'warehouse'
    ? `<section class="card table-card"><div class="panel-heading"><div><h2>گردش‌های اخیر انبار</h2><p>آخرین ورود، خروج و انتقال ثبت‌شده</p></div><button class="panel-action" data-nav="inventory">مشاهده همه ${icon('chevronLeft',13)}</button></div><div class="table-scroll"><table><thead><tr><th>کالا</th><th>نوع گردش</th><th>مقدار</th><th>انبار</th><th>وضعیت</th></tr></thead><tbody>${db.movements.slice(0,5).map(m=>`<tr><td><span class="cell-title">${esc(m.productName)}</span><span class="cell-sub">${esc(m.date)}</span></td><td>${movementLabel(m.type)}</td><td>${numberString(m.quantity)} ${esc(m.unit)}</td><td>${esc(m.warehouse)}</td><td><span class="status ${m.synced?'active':'pending'}">${m.synced?'همگام':'در صف'}</span></td></tr>`).join('')}</tbody></table></div></section>`
    : `<section class="card table-card"><div class="panel-heading"><div><h2>${db.role==='customer'?'آخرین فاکتورهای شما':'آخرین فاکتورها'}</h2><p>آخرین تراکنش‌های ثبت‌شده در سیستم</p></div><button class="panel-action" data-nav="invoices">مشاهده همه ${icon('chevronLeft',13)}</button></div><div class="table-scroll">${renderRecentInvoiceTable(recent)}</div></section>`;
  return `
    <div class="welcome-row"><div class="welcome-title"><div class="welcome-icon">${icon(db.role==='warehouse'?'warehouse':'trend',20)}</div><div><h1>${db.role==='customer'?'سلام، آریا 👋':`روز بخیر، ${esc(activeRole().name.split(' ')[0])} 👋`}</h1><p>${db.role==='warehouse'?'خلاصه عملیات انبار و وضعیت همگام‌سازی':`امروز ${TODAY_LONG} است؛ این خلاصه فعالیت ${db.role==='investor'?'سرمایه‌گذاری شما':'کسب‌وکار'} شماست.`}</p></div></div><select class="period-select" id="dashboard-period" aria-label="بازه گزارش"><option>امروز</option><option>۷ روز اخیر</option><option>این ماه</option></select></div>
    <div class="kpi-grid">${kpis.map(renderKpi).join('')}</div>
    ${db.role==='warehouse' ? renderOfflineBanner() : ''}
    <div class="dashboard-grid">
      <section class="card panel"><div class="panel-heading"><div><h2>${chartTitle}</h2><p>مقایسه عملکرد این هفته با هفته گذشته</p></div><div class="chart-legend"><span><i class="legend-dot purple"></i>این هفته</span><span><i class="legend-dot light"></i>هفته قبل</span></div></div><div class="chart-summary"><strong class="chart-total">${chartAmount}</strong><span class="trend">${icon('arrowUp',12)}۱۲٫۸٪</span><span class="chart-caption">نسبت به بازه قبل</span></div>${renderLineChart()}</section>
      ${canMoney ? `<section class="card panel channel-card"><div class="panel-heading"><div><h2>${db.role==='accountant'?'ترکیب دریافت‌ها':'ترکیب فروش'}</h2><p>بر اساس روش پرداخت</p></div><button class="btn-icon" data-nav="reports" aria-label="گزارش‌ها">${icon('more',16)}</button></div><div class="donut-row"><div class="donut"><div class="donut-center"><strong>۸۴٫۵</strong><span>میلیون تومان</span></div></div><div class="channel-list"><div class="channel-item"><span class="channel-label"><i style="background:#786fea"></i>نقدی</span><strong>۴۷٪</strong></div><div class="channel-item"><span class="channel-label"><i style="background:#45bda1"></i>چک مستقیم</span><strong>۲۷٪</strong></div><div class="channel-item"><span class="channel-label"><i style="background:#f0ab68"></i>سرمایه‌گذار</span><strong>۱۷٪</strong></div><div class="channel-item"><span class="channel-label"><i style="background:#e5e8f1"></i>سایر</span><strong>۹٪</strong></div></div></div><div class="inline-hint">${icon('trend',13)} سهم فروش نقدی نسبت به هفته قبل ۴٪ رشد داشته است.</div></section>` : `<section class="card panel"><div class="panel-heading"><div><h2>عملیات سریع</h2><p>دسترسی به کارهای پرتکرار</p></div></div><div class="low-stock-list"><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:8px" data-action="create-movement">${icon('transfer',18)}ثبت گردش کالا</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:8px" data-nav="products">${icon('box',18)}جستجوی کالا</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc" data-action="sync-now">${icon('sync',18)}همگام‌سازی داده‌ها</button></div></section>`}
    </div>
    <div class="bottom-grid">
      ${recentPanel}
      <section class="card panel"><div class="panel-heading"><div><h2>${db.role==='warehouse'?'نیازمند تأمین':'هشدار موجودی انبار'}</h2><p>کالاهای نزدیک به حداقل موجودی</p></div><button class="panel-action" data-nav="inventory">انبار ${icon('chevronLeft',13)}</button></div><div class="low-stock-list">${lowStock.map((p,i)=>`<div class="low-stock-item"><div class="product-thumb ${p.color}">${icon('box',18)}</div><div class="low-stock-meta"><strong>${esc(p.name)}</strong><span>${esc(p.code)} · ${esc(p.warehouse)}</span></div><div class="stock-remaining"><strong>${numberString(p.stockBase)}</strong><span>${esc(p.baseUnit)} باقی‌مانده</span></div></div>`).join('')}</div></section>
    </div>`;
}
function renderLineChart() {
  return `<div class="chart-wrap"><svg viewBox="0 0 690 225" preserveAspectRatio="none" role="img" aria-label="نمودار روند فروش هفتگی"><defs><linearGradient id="sales-area" x1="0" x2="0" y1="0" y2="1"><stop offset="0" stop-color="#8077ea" stop-opacity=".22"/><stop offset="1" stop-color="#8077ea" stop-opacity="0"/></linearGradient></defs><line class="chart-grid-line" x1="45" y1="24" x2="680" y2="24"/><line class="chart-grid-line" x1="45" y1="68" x2="680" y2="68"/><line class="chart-grid-line" x1="45" y1="112" x2="680" y2="112"/><line class="chart-grid-line" x1="45" y1="156" x2="680" y2="156"/><text class="chart-y-label" x="4" y="27">۱۰۰م</text><text class="chart-y-label" x="9" y="71">۷۵م</text><text class="chart-y-label" x="9" y="115">۵۰م</text><text class="chart-y-label" x="9" y="159">۲۵م</text><path class="chart-area" d="M55 129 C85 117 93 106 130 116 S183 147 220 111 S278 62 313 88 S371 119 405 86 S463 72 500 90 S557 43 590 61 S642 75 670 35 L670 174 L55 174Z"/><path class="chart-line secondary" d="M55 143 C88 150 99 129 130 136 S188 111 220 137 S276 122 313 123 S372 94 405 117 S464 129 500 112 S558 113 590 98 S640 105 670 88"/><path class="chart-line" d="M55 129 C85 117 93 106 130 116 S183 147 220 111 S278 62 313 88 S371 119 405 86 S463 72 500 90 S557 43 590 61 S642 75 670 35"/><circle cx="590" cy="61" r="4.5" fill="#fff" stroke="#8178e8" stroke-width="2.5"/><text class="chart-x-label" x="50" y="202">شنبه</text><text class="chart-x-label" x="150" y="202">یکشنبه</text><text class="chart-x-label" x="250" y="202">دوشنبه</text><text class="chart-x-label" x="352" y="202">سه‌شنبه</text><text class="chart-x-label" x="455" y="202">چهارشنبه</text><text class="chart-x-label" x="552" y="202">پنجشنبه</text><text class="chart-x-label" x="646" y="202">جمعه</text></svg></div>`;
}
function renderRecentInvoiceTable(list) {
  if (!list.length) return `<div class="empty-state">هنوز فاکتوری ثبت نشده است.</div>`;
  return `<table><thead><tr><th>شماره فاکتور</th><th>مشتری</th><th>مبلغ کل</th><th>وضعیت</th></tr></thead><tbody>${list.slice(0,5).map(inv=>`<tr><td><span class="cell-title">${esc(inv.number)}</span><span class="cell-sub">${esc(inv.date)}</span></td><td><div class="cell-main"><div class="cell-avatar">${esc(shortName(inv.customerName))}</div><div class="cell-title">${esc(inv.customerName)}</div></div></td><td>${canSeeMoney()?`<span class="cell-title">${toman(inv.total)}</span>`:'—'}</td><td><span class="status ${statusClass(inv.status)}">${statusLabel(inv.status)}</span></td></tr>`).join('')}</tbody></table>`;
}
function renderOfflineBanner() {
  return `<div class="offline-banner"><div class="offline-banner-icon">${icon('wifi',20)}</div><div class="offline-banner-text"><strong>${navigator.onLine?'همگام‌سازی انبار فعال است':'شما در حالت آفلاین هستید'}</strong><span>${db.syncQueue.length ? `${faNum(db.syncQueue.length)} عملیات روی این دستگاه ذخیره شده و پس از اتصال همگام می‌شود.` : `آخرین همگام‌سازی ${esc(db.settings.lastSync)} · اطلاعات این دستگاه ذخیره می‌شود.`}</span></div><button class="btn btn-sm" data-action="sync-now">${icon('sync',14)}همگام‌سازی</button></div>`;
}
function renderDashboard() {
  if (db.role === 'investor') return renderInvestorDashboard();
  return renderAdminDashboard();
}
function renderInvoices() {
  const isCustomer = db.role === 'customer';
  const visible = isCustomer ? db.invoices.filter(i=>i.customerId==='c-01') : db.role==='admin' ? db.invoices : db.invoices.filter(i=>!['خرید','برگشت از خرید'].includes(i.type));
  const filtered = visible.filter(i => currentInvoiceFilter === 'all' || i.status === currentInvoiceFilter).filter(i => !globalSearch || `${i.number} ${i.customerName}`.includes(globalSearch));
  const confirmed = visible.filter(i=>i.status==='confirmed'&&i.type==='فروش');
  const actions = pageAllowed('invoices') && db.role !== 'customer' ? `${actionButton('create-invoice', 'ثبت فاکتور جدید', 'plus')}${db.role==='admin'?actionButton('create-purchase','ثبت فاکتور خرید','truck','btn-secondary'):''}` : '';
  return `${pageHead(isCustomer?'فاکتورها و سفارش‌های شما':'فاکتورها و پیش‌فاکتورها',isCustomer?'سوابق خرید و وضعیت سفارش‌های ثبت‌شده':'مدیریت پیش‌فاکتور، فروش و برگشت از فروش',actions)}
    ${canSeeMoney()?`<div class="summary-strip"><div class="card summary-tile"><span>فروش تأییدشده این ماه</span><strong>${toman(confirmed.reduce((s,i)=>s+i.total,0))}</strong></div><div class="card summary-tile"><span>تعداد فاکتور</span><strong>${faNum(visible.length)} <em>فقره</em></strong></div><div class="card summary-tile"><span>پیش‌فاکتورهای باز</span><strong>${faNum(visible.filter(i=>i.status==='draft').length)} <em>فقره</em></strong></div><div class="card summary-tile"><span>${isCustomer?'مانده حساب شما':'میانگین هر فاکتور'}</span><strong>${toman(isCustomer?36800000:confirmed.length?Math.round(confirmed.reduce((s,i)=>s+i.total,0)/confirmed.length):0)}</strong></div></div>`:''}
    <div class="toolbar"><label class="toolbar-search">${icon('search',15)}<input id="invoice-search" data-local-search placeholder="جستجو بر اساس شماره یا نام مشتری" value="${esc(globalSearch)}" /></label><div class="filter-tabs"><button class="filter-tab ${currentInvoiceFilter==='all'?'active':''}" data-invoice-filter="all">همه</button><button class="filter-tab ${currentInvoiceFilter==='confirmed'?'active':''}" data-invoice-filter="confirmed">تأییدشده</button><button class="filter-tab ${currentInvoiceFilter==='draft'?'active':''}" data-invoice-filter="draft">پیش‌نویس</button></div><select class="filter-select"><option>همه روش‌های فروش</option><option>نقدی</option><option>چک مستقیم</option><option>سرمایه‌گذار</option></select><button class="btn btn-secondary btn-sm" data-action="export-invoices">${icon('download',14)}خروجی اکسل</button></div>
    <section class="card data-card"><div class="table-scroll"><table><thead><tr><th>شماره</th><th>مشتری / تأمین‌کننده</th><th>تاریخ</th><th>نوع فروش</th><th>اقلام</th>${canSeeMoney()?'<th>مبلغ کل</th>':''}<th>وضعیت</th><th>عملیات</th></tr></thead><tbody>${filtered.length?filtered.map(inv=>`<tr><td><span class="cell-title">${esc(inv.number)}</span></td><td><div class="cell-main"><div class="cell-avatar">${esc(shortName(inv.customerName))}</div><div><span class="cell-title">${esc(inv.customerName)}</span><span class="cell-sub">${esc(inv.type)}</span></div></div></td><td>${esc(inv.date)}</td><td><span class="type-badge">${esc(modeLabel(inv.mode))}</span></td><td>${faNum(inv.itemCount || (inv.items||[]).length || 1)} قلم</td>${canSeeMoney()?`<td><span class="cell-title">${toman(inv.total)}</span></td>`:''}<td><span class="status ${statusClass(inv.status)}">${statusLabel(inv.status)}</span></td><td><div class="action-cell"><button data-action="invoice-details" data-id="${esc(inv.id)}" title="مشاهده">${icon('eye',14)}</button><button data-action="print-invoice" data-id="${esc(inv.id)}" title="چاپ">${icon('printer',14)}</button>${inv.status==='draft'&&db.role!=='customer'&&(inv.type!=='خرید'||db.role==='admin')?`<button data-action="confirm-invoice" data-id="${esc(inv.id)}" title="تأیید">${icon('check',14)}</button>`:''}</div></td></tr>`).join(''):`<tr><td colspan="8"><div class="empty-state">فاکتوری با این مشخصات پیدا نشد.</div></td></tr>`}</tbody></table></div><div class="data-card-footer"><span>نمایش ${faNum(filtered.length)} فاکتور از ${faNum(visible.length)}</span><div class="pagination"><button class="page-number">‹</button><button class="page-number current">۱</button><button class="page-number">۲</button><button class="page-number">›</button></div></div></section>`;
}
function renderProducts() {
  const groups = ['همه کالاها', ...new Set(db.products.map(p=>p.group))];
  let list = db.products.filter(p => currentProductGroup==='همه کالاها' || p.group===currentProductGroup).filter(p=>!globalSearch || `${p.code} ${p.name} ${p.group}`.toLowerCase().includes(globalSearch.toLowerCase()));
  if (db.role === 'customer') list = list.filter(p => p.stockBase > 0);
  const canManage = db.role==='admin';
  const actions = canManage ? actionButton('add-product','افزودن کالا','plus') : '';
  return `${pageHead(db.role==='customer'?'کاتالوگ محصولات':'کالاها و قیمت‌گذاری',db.role==='customer'?'موجودی کالاهای قابل سفارش را مشاهده کنید':'مدیریت گروه کالا، واحدهای فروش و موجودی پایه',actions)}
    ${canSeeCost()?`<div class="inline-hint" style="margin:-5px 0 13px">${icon('shield',14)} قیمت خرید محرمانه است و فقط برای نقش مدیر نمایش داده می‌شود. قیمت فروش در فاکتور به‌صورت خودکار محاسبه می‌شود.</div>`:''}
    <div class="toolbar"><label class="toolbar-search">${icon('search',15)}<input id="product-search" data-local-search placeholder="جستجوی نام، کد کالا یا گروه" value="${esc(globalSearch)}" /></label>${db.role==='admin'?`<button class="btn btn-secondary btn-sm" data-action="import-template" data-template="products">${icon('upload',14)}ورود اطلاعات</button><button class="btn btn-secondary btn-sm" data-action="download-template" data-template="products">${icon('download',14)}قالب اکسل</button>`:''}</div>
    <div class="filter-chips">${groups.map(g=>`<button class="chip ${currentProductGroup===g?'active':''}" data-product-group="${esc(g)}">${esc(g)}${g==='همه کالاها'?` (${faNum(db.products.length)})`:''}</button>`).join('')}</div>
    <div class="product-grid">${list.length?list.map(p=>{const ratio=Math.min(100,Math.round(p.stockBase/Math.max(p.minStock*2,1)*100));const low=p.stockBase<=p.minStock;return `<article class="card product-card"><div class="product-card-top"><div class="product-art ${p.color}">${icon('box',24)}</div><button class="btn-icon" data-action="product-details" data-id="${esc(p.id)}" aria-label="جزئیات">${icon('more',15)}</button></div><h3>${esc(p.name)}</h3><div class="product-code">${esc(p.code)} · ${esc(p.group)}</div><div class="product-tags"><span class="type-badge">واحد پایه: ${esc(p.baseUnit)}</span><span class="status ${low?'draft':'active'}">${low?'موجودی کم':'موجود'}</span></div><div class="product-stat-row"><div class="product-stat">موجودی فعلی<strong>${stockText(p)}</strong></div>${canSeeCost()?`<div class="product-stat" style="text-align:left">قیمت خرید / ${esc(p.baseUnit)}<strong>${toman(p.baseCost)}</strong></div>`:db.role==='customer'?`<div class="product-stat" style="text-align:left">قیمت شما<strong>${toman(roundedPrice(applyTomanPercent(p.baseSell,priceGroupAdjustment('c-01'))))}</strong></div>`:`<div class="product-stat" style="text-align:left">حداقل موجودی<strong>${numberString(p.minStock)} ${esc(p.baseUnit)}</strong></div>`}</div><div class="stock-meter ${low?'low':''}"><span style="width:${ratio}%"></span></div></article>`;}).join(''):`<div class="card empty-state" style="grid-column:1/-1">کالایی با این مشخصات پیدا نشد.</div>`}</div>`;
}
function renderCustomers() {
  const isCustomer = db.role==='customer';
  const customers = isCustomer ? db.customers.filter(c=>c.id==='c-01') : db.customers.filter(c=>!globalSearch || `${c.name} ${c.phone} ${c.code}`.toLowerCase().includes(globalSearch.toLowerCase()));
  const actions = !isCustomer && db.role!=='sales' ? actionButton('add-customer','مشتری جدید','plus') : !isCustomer ? actionButton('create-invoice','ثبت فاکتور','plus') : '';
  return `${pageHead(isCustomer?'حساب کاربری شما':'مدیریت مشتریان',isCustomer?'اطلاعات حساب، فاکتورها و مانده شما':'اطلاعات تماس، گروه قیمت و وضعیت حساب مشتریان',actions)}
    ${!isCustomer?`<div class="summary-strip"><div class="card summary-tile"><span>مشتریان فعال</span><strong>${faNum(db.customers.filter(c=>c.active).length)} <em>مشتری</em></strong></div><div class="card summary-tile"><span>مجموع مطالبات</span><strong>${toman(db.customers.reduce((s,c)=>s+c.balance,0))}</strong></div><div class="card summary-tile"><span>نزدیک سقف اعتبار</span><strong>${faNum(db.customers.filter(c=>c.balance>c.limit*.75).length)} <em>مشتری</em></strong></div><div class="card summary-tile"><span>گروه‌های قیمت</span><strong>۴ <em>گروه</em></strong></div></div>`:''}
    <div class="toolbar"><label class="toolbar-search">${icon('search',15)}<input data-local-search placeholder="جستجو بر اساس نام، کد یا شماره تماس" value="${esc(globalSearch)}" /></label>${!isCustomer?`<select class="filter-select"><option>همه گروه‌های مشتری</option><option>همکاران ویژه</option><option>همکاران</option><option>خرده‌فروشی</option></select><select class="filter-select"><option>همه وضعیت‌ها</option><option>فعال</option><option>غیرفعال</option></select>${db.role==='admin'?`<button class="btn btn-secondary btn-sm" data-action="import-template" data-template="customers">${icon('upload',14)}ورود CSV</button>`:''}`:''}</div>
    <section class="card data-card"><div class="table-scroll"><table><thead><tr><th>مشتری</th><th>نوع</th><th>شماره تماس</th><th>گروه قیمت</th><th>سقف اعتبار</th><th>مانده حساب</th><th>وضعیت</th><th>عملیات</th></tr></thead><tbody>${customers.map(c=>`<tr><td><div class="cell-main"><div class="cell-avatar">${esc(shortName(c.name))}</div><div><span class="cell-title">${esc(c.name)}</span><span class="cell-sub">${esc(c.code)}</span></div></div></td><td><span class="type-badge">${esc(c.type)}</span></td><td>${esc(c.phone)}</td><td>${isCustomer?'—':esc(c.group)}</td><td>${canSeeMoney()?toman(c.limit):'—'}</td><td>${canSeeMoney()?`<span class="cell-title ${c.balance>c.limit*.75?'':' '}">${toman(c.balance)}</span>`:'—'}</td><td><span class="status ${c.active?'active':'cancelled'}">${c.active?'فعال':'غیرفعال'}</span></td><td><div class="action-cell"><button data-action="customer-account" data-id="${esc(c.id)}" title="حساب مشتری">${icon('eye',14)}</button>${!isCustomer?`<button data-action="customer-invoice" data-id="${esc(c.id)}" title="فاکتور جدید">${icon('invoice',14)}</button>`:''}</div></td></tr>`).join('')}</tbody></table></div><div class="data-card-footer"><span>نمایش ${faNum(customers.length)} مشتری</span><div class="pagination"><button class="page-number current">۱</button><button class="page-number">۲</button><button class="page-number">›</button></div></div></section>`;
}
function renderSuppliers() {
  const rows=db.suppliers.filter(s=>!globalSearch||`${s.name} ${s.phone} ${s.code}`.toLowerCase().includes(globalSearch.toLowerCase()));
  return `${pageHead('مدیریت تأمین‌کنندگان','اطلاعات تماس، مانده پرداختنی و سوابق خرید',actionButton('add-supplier','تأمین‌کننده جدید','plus'))}
    <div class="summary-strip"><div class="card summary-tile"><span>تأمین‌کنندگان فعال</span><strong>${faNum(db.suppliers.length)} <em>مجموع</em></strong></div><div class="card summary-tile"><span>مانده پرداختنی</span><strong>${toman(db.suppliers.reduce((sum,s)=>sum+s.balance,0))}</strong></div><div class="card summary-tile"><span>چک‌های پرداختنی</span><strong>${toman(db.cheques.filter(c=>c.type==='پرداختی'&&c.status!=='cleared').reduce((sum,c)=>sum+c.amount,0))}</strong></div><div class="card summary-tile"><span>فاکتورهای خرید این ماه</span><strong>${faNum(db.invoices.filter(i=>i.type==='خرید').length)} <em>فقره</em></strong></div></div>
    <div class="toolbar"><label class="toolbar-search">${icon('search',15)}<input data-local-search placeholder="جستجوی نام، کد یا شماره تماس تأمین‌کننده" value="${esc(globalSearch)}" /></label><button class="btn btn-secondary btn-sm" data-action="create-purchase">${icon('invoice',14)}ثبت فاکتور خرید</button>${db.role==='admin'?`<button class="btn btn-secondary btn-sm" data-action="import-template" data-template="suppliers">${icon('upload',14)}ورود CSV</button>`:''}</div>
    <section class="card data-card"><div class="table-scroll"><table><thead><tr><th>تأمین‌کننده</th><th>کد</th><th>شماره تماس</th><th>نشانی</th><th>مانده پرداختنی</th><th>یادداشت</th><th>عملیات</th></tr></thead><tbody>${rows.map(s=>`<tr><td><div class="cell-main"><div class="cell-avatar">${esc(shortName(s.name))}</div><span class="cell-title">${esc(s.name)}</span></div></td><td>${esc(s.code)}</td><td>${esc(s.phone)}</td><td>${esc(s.address)}</td><td><span class="cell-title">${toman(s.balance)}</span></td><td>${esc(s.notes||'—')}</td><td><div class="action-cell"><button data-action="supplier-purchases" data-id="${esc(s.id)}" title="خرید جدید">${icon('invoice',14)}</button></div></td></tr>`).join('')}</tbody></table></div><div class="data-card-footer"><span>نمایش ${faNum(rows.length)} تأمین‌کننده</span><span class="subtle-note">اطلاعات تأمین‌کنندگان فقط برای مدیر و حسابدار قابل مشاهده است.</span></div></section>`;
}
function supplierModal() {
  const body=`<form id="supplier-form" class="form-grid"><div class="field"><label>نام تأمین‌کننده</label><input name="name" required /></div><div class="field"><label>شماره تماس</label><input name="phone" /></div><div class="field full"><label>نشانی</label><input name="address" /></div><div class="field full"><label>یادداشت</label><textarea name="notes"></textarea></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ذخیره تأمین‌کننده</button></div></form>`;
  openModal({title:'ثبت تأمین‌کننده جدید',subtitle:'این اطلاعات فقط برای مدیر و حسابدار نمایش داده می‌شود.',body});
}
function renderInventory() {
  const movements = db.movements.filter(m=>!globalSearch || `${m.productName} ${m.reference} ${m.warehouse}`.toLowerCase().includes(globalSearch.toLowerCase()));
  const actions = actionButton('create-movement','ثبت گردش کالا','plus');
  const lowCount = db.products.filter(p=>p.stockBase<=p.minStock).length;
  return `${pageHead('انبار و گردش کالا','نمای کلی موجودی، رسید، حواله و انتقال بین انبارها',actions)}
    ${renderOfflineBanner()}
    <div class="summary-strip"><div class="card summary-tile"><span>انبارهای فعال</span><strong>${faNum(db.warehouses.length)} <em>انبار</em></strong></div><div class="card summary-tile"><span>کدهای کالای موجود</span><strong>${faNum(db.products.filter(p=>p.stockBase>0).length)} <em>قلم</em></strong></div><div class="card summary-tile"><span>کمتر از حداقل</span><strong>${faNum(lowCount)} <em>قلم</em></strong></div><div class="card summary-tile"><span>اسناد در انتظار همگام‌سازی</span><strong>${faNum(db.syncQueue.length)} <em>سند</em></strong></div></div>
    <div class="warehouse-grid"><div><section class="card panel" style="margin-bottom:14px"><div class="panel-heading"><div><h2>وضعیت انبارها</h2><p>ظرفیت و تعداد اقلام پایه هر انبار</p></div><button class="panel-action" data-action="add-warehouse">مدیریت انبارها ${icon('chevronLeft',13)}</button></div>${db.warehouses.map(wh=>`<div class="warehouse-card"><div class="warehouse-card-head"><strong>${esc(wh.name)}</strong><span>${icon('pin',12)} ${esc(wh.location)}</span></div><div class="warehouse-progress"><i style="width:${wh.percent}%"></i></div><div class="warehouse-meta"><span>${faNum(wh.stockValue)} واحد پایه</span><span>ظرفیت ${faNum(wh.percent)}٪</span></div></div>`).join('')}</section></div><div><section class="card alert-card"><div class="alert-title">${icon('alert',17)}توجه به موجودی کالا</div><p>برای جلوگیری از توقف فروش، کالاهای زیر را بررسی کنید.</p><div class="cheque-state"><i style="color:#ed9b58"></i>${faNum(lowCount)} قلم پایین‌تر از حد سفارش</div><button class="panel-action" style="margin-top:10px" data-nav="products">مشاهده کالاها ${icon('chevronLeft',13)}</button></section><section class="card panel" style="margin-top:13px"><div class="panel-heading"><div><h2>کارهای سریع</h2><p>عملیات ثبت انبار</p></div></div><div class="low-stock-list"><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:7px" data-action="create-movement">${icon('plus',17)}ثبت رسید / حواله</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc" data-action="inventory-count">${icon('clipboard',17)}ثبت شمارش دوره‌ای</button></div></section></div></div>
    <section class="card data-card" style="margin-top:15px"><div class="panel-heading"><div><h2>گردش‌های اخیر</h2><p>ثبت‌های محلی و همگام‌سازی‌شده</p></div><label class="toolbar-search" style="flex:0 1 250px;margin:0">${icon('search',14)}<input data-local-search placeholder="جستجوی گردش کالا" value="${esc(globalSearch)}" /></label></div><div class="table-scroll"><table><thead><tr><th>نوع گردش</th><th>کالا</th><th>انبار</th><th>مقدار</th><th>سند مرجع</th><th>کاربر</th><th>تاریخ</th><th>همگام‌سازی</th></tr></thead><tbody>${movements.slice(0,12).map(m=>`<tr><td><span class="type-badge">${movementLabel(m.type)}</span></td><td><span class="cell-title">${esc(m.productName)}</span></td><td>${esc(m.warehouse)}</td><td>${numberString(m.quantity)} ${esc(m.unit)}</td><td>${esc(m.reference || '—')}</td><td>${esc(m.user)}</td><td>${esc(m.date)}</td><td><span class="status ${m.synced?'active':'pending'}">${m.synced?'همگام':'در صف'}</span></td></tr>`).join('')}</tbody></table></div><div class="data-card-footer"><span>${faNum(movements.length)} گردش ثبت‌شده · ${faNum(db.syncQueue.length)} مورد آفلاین</span><button class="panel-action" data-action="sync-now">همگام‌سازی اکنون ${icon('sync',13)}</button></div></section>`;
}
function movementLabel(type) { return ({purchase_in:'رسید خرید',sale_out:'حواله فروش',transfer_in:'انتقال ورودی',transfer_out:'انتقال خروجی',adjustment:'اصلاح موجودی',stock_in:'ورود کالا',stock_out:'خروج کالا'}[type] || type); }
function renderCheques() {
  let list = db.cheques.filter(ch=>!globalSearch || `${ch.number} ${ch.party} ${ch.bank}`.toLowerCase().includes(globalSearch.toLowerCase()));
  if (db.role==='investor') list=list.filter(ch=>ch.holder==='سرمایه‌گذار' && ch.investorId==='inv-01');
  const dueSoon = list.filter(ch=>ch.status==='in_hand' || ch.status==='deposited').length;
  const actions = db.role==='admin'||db.role==='accountant' ? actionButton('add-cheque','ثبت چک جدید','plus') : '';
  return `${pageHead(db.role==='investor'?'چک‌های سرمایه‌گذاری':'مدیریت چک‌ها',db.role==='investor'?'چک‌های مرتبط با معاملات شما':'چک‌های دریافتی، پرداختی و وضعیت سررسید',actions)}
    <div class="summary-strip"><div class="card summary-tile"><span>چک‌های در دست</span><strong>${faNum(dueSoon)} <em>فقره</em></strong></div><div class="card summary-tile"><span>مبلغ سررسید ۷ روز آینده</span><strong>${toman(list.filter(ch=>ch.status==='in_hand').reduce((s,ch)=>s+ch.amount,0))}</strong></div><div class="card summary-tile"><span>چک‌های برگشتی</span><strong>${faNum(list.filter(ch=>ch.status==='bounced').length)} <em>فقره</em></strong></div><div class="card summary-tile"><span>چک‌های واگذارشده</span><strong>${faNum(list.filter(ch=>ch.status==='transferred'||ch.status==='deposited').length)} <em>فقره</em></strong></div></div>
    <div class="toolbar"><label class="toolbar-search">${icon('search',15)}<input data-local-search placeholder="جستجوی شماره چک، بانک یا طرف حساب" value="${esc(globalSearch)}" /></label><select class="filter-select"><option>همه انواع</option><option>دریافتی</option><option>پرداختی</option></select><select class="filter-select"><option>همه وضعیت‌ها</option><option>در دست</option><option>وصول شده</option><option>برگشتی</option></select><button class="btn btn-secondary btn-sm" data-action="export-cheques">${icon('download',14)}خروجی اکسل</button></div>
    <section class="card data-card"><div class="table-scroll"><table><thead><tr><th>شماره چک</th><th>بانک</th><th>طرف حساب</th><th>نوع</th><th>تاریخ سررسید</th><th>مبلغ</th><th>وضعیت</th><th>دارنده</th><th>عملیات</th></tr></thead><tbody>${list.map(ch=>`<tr><td><span class="cell-title">${esc(ch.number)}</span></td><td>${esc(ch.bank)}</td><td><span class="cell-title">${esc(ch.party)}</span></td><td><span class="type-badge">${esc(ch.type)}</span></td><td>${esc(ch.due)}</td><td><span class="cell-title">${toman(ch.amount)}</span></td><td><span class="status ${statusClass(ch.status)}">${statusLabel(ch.status)}</span></td><td>${esc(ch.holder)}</td><td><div class="action-cell"><button data-action="cycle-cheque" data-id="${esc(ch.id)}" title="تغییر وضعیت">${icon('sync',14)}</button><button data-action="cheque-details" data-id="${esc(ch.id)}" title="جزئیات">${icon('eye',14)}</button></div></td></tr>`).join('')}</tbody></table></div><div class="data-card-footer"><span>نمایش ${faNum(list.length)} چک</span><span class="subtle-note">برای تغییر وضعیت روی آیکن همگام‌سازی بزنید.</span></div></section>`;
}
function renderInvestors() {
  const isInvestor = db.role==='investor';
  const investorId = isInvestor ? 'inv-01' : null;
  const deals = db.deals.filter(d=>!investorId || d.investorId===investorId).filter(d=>!globalSearch || `${d.investor} ${d.customer}`.toLowerCase().includes(globalSearch.toLowerCase()));
  const investors = isInvestor ? db.investors.filter(i=>i.id===investorId) : db.investors;
  const totalProfit = deals.reduce((s,d)=>s+d.investorProfit,0);
  const openDeals = deals.filter(d=>d.status==='open');
  const actions = !isInvestor && (db.role==='admin'||db.role==='accountant') ? actionButton('add-deal','ثبت معامله جدید','plus') : '';
  return `${pageHead(isInvestor?'پرتفوی سرمایه‌گذاری من':'مدیریت سرمایه‌گذاران',isInvestor?'معاملات، سود و چک‌های مرتبط با حساب شما':'مدیریت معاملات مشترک و تاریخچه تسویه‌حساب‌ها',actions)}
    <div class="summary-strip"><div class="card summary-tile"><span>${isInvestor?'معاملات من':'سرمایه‌گذاران فعال'}</span><strong>${faNum(isInvestor?deals.length:investors.length)} <em>${isInvestor?'معامله':'نفر'}</em></strong></div><div class="card summary-tile"><span>سود سرمایه‌گذار</span><strong>${toman(totalProfit)}</strong></div><div class="card summary-tile"><span>معاملات باز</span><strong>${faNum(openDeals.length)} <em>معامله</em></strong></div><div class="card summary-tile"><span>چک‌های در اختیار</span><strong>${faNum(db.cheques.filter(c=>c.holder==='سرمایه‌گذار'&&(!isInvestor||c.investorId==='inv-01')).length)} <em>فقره</em></strong></div></div>
    ${!isInvestor?`<div class="deal-grid">${investors.map(inv=>{const own=db.deals.filter(d=>d.investorId===inv.id);return `<article class="card deal-card"><div class="deal-card-top"><div class="avatar">${esc(shortName(inv.name))}</div><span class="status active">فعال</span></div><h3>${esc(inv.name)}</h3><p>${esc(inv.phone)} · ${faNum(own.length)} معامله</p><div class="deal-numbers"><div><span>سود سرمایه‌گذار</span><strong class="deal-profit">${toman(own.reduce((s,d)=>s+d.investorProfit,0))}</strong></div><div><span>وضعیت تسویه</span><strong>${faNum(own.filter(d=>d.status==='open').length)} معامله باز</strong></div></div></article>`;}).join('')}</div>`:''}
    ${isInvestor?`<div class="inline-hint">${icon('shield',14)} اطلاعات بهای خرید تأمین‌کننده و سود بنفشه در این پنل نمایش داده نمی‌شود.</div>`:''}
    <section class="card data-card" style="margin-top:14px"><div class="panel-heading"><div><h2>${isInvestor?'معاملات من':'معاملات سرمایه‌گذاری'}</h2><p>${isInvestor?'سهم سود و وضعیت تسویه شما':'جزئیات مبلغ فروش به سرمایه‌گذار و مشتری نهایی'}</p></div>${!isInvestor&&canSeeCost()?`<button class="panel-action" data-action="investor-report">گزارش محرمانه سود ${icon('chevronLeft',13)}</button>`:''}</div><div class="table-scroll"><table><thead><tr>${!isInvestor?'<th>سرمایه‌گذار</th>':''}<th>مشتری نهایی</th><th>تاریخ</th><th>فروش بنفشه به سرمایه‌گذار</th><th>فروش به مشتری</th><th>سود سرمایه‌گذار</th>${canSeeCost()&&!isInvestor?'<th>بهای خرید (محرمانه)</th>':''}<th>چک</th><th>وضعیت</th></tr></thead><tbody>${deals.map(d=>`<tr>${!isInvestor?`<td><span class="cell-title">${esc(d.investor)}</span></td>`:''}<td>${esc(d.customer)}</td><td>${esc(d.date)}</td><td>${toman(d.companyPrice)}</td><td>${toman(d.customerPrice)}</td><td><span class="cell-title" style="color:#159878">${toman(d.investorProfit)}</span></td>${canSeeCost()&&!isInvestor?`<td>${toman(d.companyCost)}</td>`:''}<td>${faNum(d.chequeCount)} فقره</td><td><span class="status ${statusClass(d.status)}">${statusLabel(d.status)}</span></td></tr>`).join('')}</tbody></table></div><div class="data-card-footer"><span>${faNum(deals.length)} معامله · سود نمایش‌داده‌شده فقط سهم سرمایه‌گذار است</span>${!isInvestor?`<button class="panel-action" data-action="settlement">ثبت تسویه ${icon('chevronLeft',13)}</button>`:''}</div></section>`;
}
function renderInvestorDashboard() {
  const deals=db.deals.filter(d=>d.investorId==='inv-01');
  const profit=deals.reduce((s,d)=>s+d.investorProfit,0);
  const dueCheques=db.cheques.filter(c=>c.holder==='سرمایه‌گذار'&&c.investorId==='inv-01');
  const kpis=[
    {label:'معاملات فعال من',value:faNum(deals.filter(d=>d.status==='open').length),unit:'معامله',color:'purple',iconName:'investor',foot:'در جریان تسویه'},
    {label:'سود قطعی معاملات',value:toman(profit,false),unit:'تومان',color:'teal',iconName:'trend',foot:'سهم شما از معاملات'},
    {label:'چک‌های در اختیار',value:faNum(dueCheques.length),unit:'فقره',color:'orange',iconName:'cheque',foot:'سررسید نزدیک: ۱۵ مهر'},
    {label:'مانده تسویه',value:toman(deals.filter(d=>d.status==='open').reduce((s,d)=>s+d.investorProfit,0),false),unit:'تومان',color:'blue',iconName:'wallet',foot:'قابل تسویه'}
  ];
  return `<div class="welcome-row"><div class="welcome-title"><div class="welcome-icon">${icon('investor',20)}</div><div><h1>سلام، سرمایه‌گذار گرامی 👋</h1><p>خلاصه معاملات و گردش مالی شما در بنفشه</p></div></div><button class="btn btn-secondary btn-sm" data-nav="investors">مشاهده همه معاملات ${icon('chevronLeft',13)}</button></div><div class="kpi-grid">${kpis.map(renderKpi).join('')}</div><div class="inline-hint">${icon('shield',14)} این پنل فقط اطلاعات معاملات و سهم سود شما را نشان می‌دهد؛ بهای خرید بنفشه و اطلاعات سایر سرمایه‌گذاران محرمانه است.</div><div class="dashboard-grid" style="margin-top:15px"><section class="card panel"><div class="panel-heading"><div><h2>معاملات اخیر من</h2><p>مبلغ خرید از بنفشه و فروش به مشتری</p></div><button class="panel-action" data-nav="investors">مشاهده همه ${icon('chevronLeft',13)}</button></div><div class="table-scroll"><table><thead><tr><th>مشتری نهایی</th><th>تاریخ</th><th>قیمت خرید</th><th>سود شما</th><th>وضعیت</th></tr></thead><tbody>${deals.map(d=>`<tr><td><span class="cell-title">${esc(d.customer)}</span></td><td>${esc(d.date)}</td><td>${toman(d.companyPrice)}</td><td><span class="cell-title" style="color:#159878">${toman(d.investorProfit)}</span></td><td><span class="status ${statusClass(d.status)}">${statusLabel(d.status)}</span></td></tr>`).join('')}</tbody></table></div></section><section class="card panel"><div class="panel-heading"><div><h2>چک‌های من</h2><p>چک‌های دریافتی مستقیم</p></div><button class="panel-action" data-nav="cheques">همه چک‌ها ${icon('chevronLeft',13)}</button></div><div class="low-stock-list">${dueCheques.map(ch=>`<div class="low-stock-item"><div class="product-thumb teal">${icon('cheque',18)}</div><div class="low-stock-meta"><strong>${esc(ch.party)}</strong><span>${esc(ch.bank)} · سررسید ${esc(ch.due)}</span></div><div class="stock-remaining"><strong style="color:#45516b">${toman(ch.amount,false)}</strong><span>تومان</span></div></div>`).join('')}</div></section></div>`;
}
function renderReports() {
  const actions=`<button class="btn btn-secondary" data-action="export-report">${icon('download',15)}خروجی اکسل</button>`;
  return `${pageHead('گزارش‌ها و تحلیل فروش','تصویر دقیق از فروش، موجودی، حساب مشتریان و چک‌ها',actions)}<div class="toolbar"><select class="filter-select"><option>از ابتدای ماه</option><option>۷ روز اخیر</option><option>۳۰ روز اخیر</option><option>بازه دلخواه</option></select><select class="filter-select"><option>همه انبارها</option>${db.warehouses.map(w=>`<option>${esc(w.name)}</option>`).join('')}</select><select class="filter-select"><option>همه گروه‌های کالا</option>${[...new Set(db.products.map(p=>p.group))].map(g=>`<option>${esc(g)}</option>`).join('')}</select></div><div class="summary-strip"><div class="card summary-tile"><span>فروش ناخالص</span><strong>${toman(326480000)}</strong></div><div class="card summary-tile"><span>تعداد فاکتور فروش</span><strong>۱۲۸ <em>فقره</em></strong></div><div class="card summary-tile"><span>مبلغ مرجوعی</span><strong>${toman(6240000)}</strong></div>${canSeeCost()?`<div class="card summary-tile"><span>سود ناخالص</span><strong>${toman(58480000)}</strong></div>`:`<div class="card summary-tile"><span>میانگین ارزش فاکتور</span><strong>${toman(25490000)}</strong></div>`}</div><div class="report-grid"><section class="card panel"><div class="panel-heading"><div><h2>${canSeeCost()?'مقایسه خرید و فروش':'روند فروش ماهانه'}</h2><p>مبالغ به میلیون تومان</p></div><span class="type-badge">مهر ۱۴۰۵</span></div>${renderBarChart(canSeeCost())}</section><section class="card panel"><div class="panel-heading"><div><h2>فروش به تفکیک گروه کالا</h2><p>سهم هر گروه از فروش ماه جاری</p></div></div><div class="donut-row"><div class="donut" style="background:conic-gradient(#786fea 0 41%,#45bda1 41% 68%,#f0ab68 68% 85%,#6ea5e9 85% 94%,#e5e8f1 94% 100%)"><div class="donut-center"><strong>۳۲۶٫۴</strong><span>میلیون تومان</span></div></div><div class="channel-list"><div class="channel-item"><span class="channel-label"><i style="background:#786fea"></i>پروفیل</span><strong>۴۱٪</strong></div><div class="channel-item"><span class="channel-label"><i style="background:#45bda1"></i>یراق‌آلات</span><strong>۲۷٪</strong></div><div class="channel-item"><span class="channel-label"><i style="background:#f0ab68"></i>شیشه</span><strong>۱۷٪</strong></div><div class="channel-item"><span class="channel-label"><i style="background:#6ea5e9"></i>سایر</span><strong>۹٪</strong></div></div></div></section><section class="card panel"><div class="panel-heading"><div><h2>مطالبات مشتریان</h2><p>گروه‌بندی بر اساس زمان سررسید</p></div><button class="panel-action" data-nav="customers">جزئیات حساب‌ها ${icon('chevronLeft',13)}</button></div><div class="low-stock-list"><div class="low-stock-item"><div class="product-thumb teal">${icon('clock',18)}</div><div class="low-stock-meta"><strong>سررسید نشده</strong><span>تا ۳۰ روز آینده</span></div><div class="stock-remaining"><strong style="color:#45516b">${toman(146200000,false)}</strong><span>تومان</span></div></div><div class="low-stock-item"><div class="product-thumb orange">${icon('clock',18)}</div><div class="low-stock-meta"><strong>۱ تا ۳۰ روز گذشته</strong><span>نیازمند پیگیری</span></div><div class="stock-remaining"><strong style="color:#45516b">${toman(82500000,false)}</strong><span>تومان</span></div></div><div class="low-stock-item"><div class="product-thumb" style="color:#d56c77;background:#fff0f1">${icon('alert',18)}</div><div class="low-stock-meta"><strong>بیش از ۳۰ روز</strong><span>پیگیری فوری</span></div><div class="stock-remaining"><strong style="color:#45516b">${toman(57700000,false)}</strong><span>تومان</span></div></div></div></section><section class="card panel"><div class="panel-heading"><div><h2>گزارش‌های آماده</h2><p>دریافت خروجی قابل استفاده در اکسل</p></div></div><div class="low-stock-list"><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:7px" data-action="export-report">${icon('fileDown',17)}فروش به تفکیک مشتری</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:7px" data-action="export-report">${icon('fileDown',17)}موجودی کالا در انبارها</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc" data-action="export-report">${icon('fileDown',17)}سررسید چک‌ها</button></div></section></div>`;
}
function renderBarChart(showPurchases=false) {
  const rows=[['فروردین',58,44],['اردیبهشت',69,51],['خرداد',77,63],['تیر',61,54],['مرداد',85,66],['شهریور',73,61],['مهر',91,74]];
  return `<div class="report-bars">${rows.map(r=>`<div class="report-bar-group"><div class="report-bar-pair">${showPurchases?`<span class="report-bar secondary" style="height:${r[2]}%"></span>`:''}<span class="report-bar" style="height:${r[1]}%"></span></div><span class="report-bar-label">${r[0]}</span></div>`).join('')}</div><div class="report-legend"><span><i class="legend-dot purple"></i>فروش</span>${showPurchases?'<span><i class="legend-dot light"></i>خرید</span>':''}</div>`;
}
function renderSettings() {
  return `${pageHead('تنظیمات سیستم','اتصال به PocketBase، مدیریت اطلاعات محلی و نقش‌های کاربری','')}
    <div class="settings-layout"><section class="card settings-card"><h2>اتصال به سرور PocketBase</h2><p>آدرس سرور را تنظیم کنید تا عملیات پس از اتصال همگام شوند.</p><form id="settings-form" class="form-grid"><div class="field full"><label for="pb-url">آدرس پایه API</label><input id="pb-url" name="pbUrl" type="url" placeholder="https://server.example.ir" value="${esc(db.settings.pbUrl || '')}" dir="ltr"/><span class="field-hint">برای نسخه محلی، آدرس سرور PocketBase خود را وارد کنید. از قرار دادن کلید مدیر در مرورگر خودداری کنید.</span></div><div class="field"><label for="tax-rate">نرخ مالیات (درصد)</label><input id="tax-rate" name="taxRate" type="number" min="0" step="0.1" value="${esc(db.settings.taxRate ?? 0)}" /></div><div class="field"><label>وضعیت اتصال</label><input readonly value="${navigator.onLine?'دستگاه آنلاین':'دستگاه آفلاین'} · ${db.syncQueue.length?faNum(db.syncQueue.length)+' مورد در صف':'صف همگام‌سازی خالی'}" /></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',15)}ذخیره تنظیمات</button></div></form><div class="settings-row" style="margin-top:12px"><div><strong>همگام‌سازی خودکار عملیات انبار</strong><span>ارسال شناسه یکتا برای جلوگیری از ثبت تکراری</span></div><button class="switch ${db.settings.offlineMode?'on':''}" data-action="toggle-offline" aria-label="تغییر وضعیت"></button></div><div class="settings-row"><div><strong>آخرین همگام‌سازی موفق</strong><span>${esc(db.settings.lastSync || 'هنوز انجام نشده')}</span></div><button class="btn btn-secondary btn-sm" data-action="sync-now">${icon('sync',13)}اکنون</button></div></section>
    <div><section class="card settings-card"><h2>نقش‌های آزمایشی</h2><p>برای بررسی نمایش نقش‌ها از کنترل زیر استفاده کنید.</p>${Object.entries(roleInfo).map(([key,role])=>`<div class="settings-row"><div><strong>${esc(role.label)}</strong><span>${key==='admin'?'دسترسی کامل':key==='accountant'?'امور مالی، بدون قیمت خرید':key==='warehouse'?'گردش موجودی و حالت آفلاین':key==='sales'?'فروش و مشاهده موجودی':key==='investor'?'فقط معاملات خود': 'کاتالوگ و حساب شخصی'}</span></div><button class="btn ${db.role===key?'btn-soft':'btn-secondary'} btn-sm" data-role="${key}">${db.role===key?'فعال':'مشاهده'}</button></div>`).join('')}</section><section class="card settings-card" style="margin-top:13px"><h2>ورود و خروج اطلاعات</h2><p>قالب‌های CSV سازگار با Excel؛ بدون نیاز به افزونه خارجی.</p><div class="low-stock-list"><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:7px" data-action="download-template" data-template="products">${icon('download',17)}قالب کالاها</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:7px" data-action="download-template" data-template="customers">${icon('download',17)}قالب مشتریان</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc;margin-bottom:7px" data-action="download-template" data-template="suppliers">${icon('download',17)}قالب تأمین‌کنندگان</button><button class="nav-link" style="color:#5e6880;background:#f8f9fc" data-action="clear-local">${icon('trash',17)}پاک‌سازی داده‌های نمایشی</button></div></section><section class="card settings-card" style="margin-top:13px"><h2>حریم دسترسی</h2><p>داده‌های حساس باید در سمت PocketBase محافظت شوند.</p><div class="inline-hint">${icon('shield',14)} نقش فعلی: ${esc(activeRole().label)} · ${canSeeCost()?'نمایش قیمت خرید مجاز است.':'قیمت خرید و حاشیه سود در رابط کاربری مخفی است.'}</div></section></div></div>`;
}

function renderLogin() {
  document.getElementById('app').innerHTML = `<main class="login-screen"><form class="login-card" id="login-form"><div class="login-brand"><div class="brand-mark">${icon('box',24)}</div><div><div class="brand-name" style="color:#192642">بنفشه</div><div class="brand-sub" style="color:#9ba4b4">مدیریت فروش و انبار</div></div></div><h1>ورود به حساب کاربری</h1><p>برای ادامه، نقش نمایشی موردنظر را انتخاب کنید.</p><div class="field"><label for="login-phone">نام کاربری / شماره تماس</label><input id="login-phone" placeholder="شماره تماس یا نام کاربری" autocomplete="username" /></div><div class="field"><label for="login-password">گذرواژه</label><input id="login-password" type="password" placeholder="گذرواژه" autocomplete="current-password" /></div><div class="field"><label for="login-role">نقش آزمایشی</label><select id="login-role">${Object.entries(roleInfo).map(([key,r])=>`<option value="${key}">${esc(r.label)}</option>`).join('')}</select></div><button class="btn btn-primary" type="submit" style="width:100%;height:42px;margin-top:5px">ورود به بنفشه ${icon('arrowLeft',15)}</button><div class="login-info">این نسخه شامل داده‌های آزمایشی محلی است. برای ورود واقعی، PocketBase را پیکربندی کنید.</div></form></main>`;
}

// Small reusable data export (CSV opens directly in Excel; UTF-8 BOM included).
function downloadCSV(filename, rows) {
  const csv = '\ufeff' + rows.map(row => row.map(v => `"${String(v ?? '').replace(/"/g,'""')}"`).join(',')).join('\r\n');
  const blob = new Blob([csv], {type:'text/csv;charset=utf-8'});
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a'); a.href=url; a.download=filename; a.click(); URL.revokeObjectURL(url);
}
function openModal({title,subtitle='',body='',footer='',wide=false}) {
  document.getElementById('modal-root').innerHTML = `<div class="modal-backdrop" data-backdrop><section class="modal ${wide?'wide':''}" role="dialog" aria-modal="true"><header class="modal-header"><div><h2>${title}</h2>${subtitle?`<p>${subtitle}</p>`:''}</div><button class="modal-close" data-action="close-modal" aria-label="بستن">${icon('close',15)}</button></header><div class="modal-body">${body}</div>${footer?`<footer class="modal-footer">${footer}</footer>`:''}</section></div>`;
}
function closeModal() { document.getElementById('modal-root').innerHTML=''; }
function toast(message, type='success') {
  const root=document.getElementById('toast-root');
  const node=document.createElement('div');
  node.className=`toast ${type==='error'?'error':type==='warning'?'warning':''}`;
  node.innerHTML=`${icon(type==='error'?'alert':type==='warning'?'alert':'check',16)}<span>${esc(message)}</span>`;
  root.appendChild(node);
  window.setTimeout(()=>{node.classList.add('out');window.setTimeout(()=>node.remove(),250);},3200);
}
function roleModal() {
  const body=`<p style="color:#8e98aa;font-size:10px;margin:0 0 14px">انتخاب نقش، منوها و داده‌های قابل مشاهده را در نسخه آزمایشی تغییر می‌دهد.</p><div class="low-stock-list">${Object.entries(roleInfo).map(([key,r])=>`<button class="nav-link" style="color:#56617a;background:#f8f9fc;margin-bottom:7px;justify-content:flex-start" data-role="${key}"><span class="avatar" style="width:30px;height:30px;flex-basis:30px;border-radius:9px;background:linear-gradient(140deg,#aaa3ff,#6f66df)">${esc(r.short)}</span><span style="flex:1">${esc(r.label)}</span>${db.role===key?`<span style="color:#6f68d9">فعال</span>`:icon('chevronLeft',14)}</button>`).join('')}</div><div class="inline-hint">${icon('shield',14)} در استقرار واقعی، مجوز دسترسی باید در PocketBase نیز اعمال شود.</div>`;
  openModal({title:'تغییر نقش کاربری',subtitle:'مشاهده نسخه متناسب با هر کاربر',body});
}
function customerModal() {
  const body=`<form id="customer-form" class="form-grid"><div class="field"><label>نام مشتری</label><input name="name" required placeholder="نام شخص یا شرکت" /></div><div class="field"><label>شماره تماس</label><input name="phone" required placeholder="۰۹۱۲..." /></div><div class="field"><label>نوع مشتری</label><select name="type"><option>عمده</option><option>خرده</option><option>متفرقه</option></select></div><div class="field"><label>گروه قیمت</label><select name="group"><option>همکاران</option><option>همکاران ویژه</option><option>خرده‌فروشی</option><option>پروژه‌ای</option></select></div><div class="field"><label>سقف اعتبار (تومان)</label><input name="limit" type="number" min="0" value="50000000" /></div><div class="field"><label>شهر</label><input name="city" placeholder="تهران" /></div><div class="field full"><label>نشانی</label><input name="address" placeholder="نشانی مشتری" /></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ذخیره مشتری</button></div></form>`;
  openModal({title:'ثبت مشتری جدید',subtitle:'اطلاعات پایه و شرایط حساب مشتری',body});
}
function productModal(product = null) {
  const body=`<form id="product-form" class="form-grid"><div class="field"><label>نام کالا</label><input name="name" required value="${esc(product?.name||'')}" placeholder="مثلاً پروفیل ۶۰ سفید" /></div><div class="field"><label>کد کالا</label><input name="code" required value="${esc(product?.code||'')}" placeholder="PR-060-WH" /></div><div class="field"><label>گروه کالا</label><select name="group">${[...new Set(db.products.map(p=>p.group))].map(g=>`<option ${product?.group===g?'selected':''}>${esc(g)}</option>`).join('')}<option>سایر</option></select></div><div class="field"><label>واحد پایه</label><select name="baseUnit"><option>شاخه</option><option>کیلو</option><option>عدد</option><option>متر</option><option>مترمربع</option></select></div><div class="field"><label>موجودی افتتاحیه</label><input name="stock" type="number" step="0.001" min="0" value="${product?.stockBase||0}" /></div><div class="field"><label>حداقل موجودی</label><input name="minStock" type="number" min="0" value="${product?.minStock||10}" /></div>${canSeeCost()?`<div class="field"><label>قیمت خرید پایه (تومان)</label><input name="baseCost" type="number" min="0" value="${product?.baseCost||0}" /></div>`:''}<div class="field full"><span class="field-hint">واحدهای فروش و نسخه‌بندی ضریب تبدیل از جزئیات کالا قابل تنظیم است. قیمت فروش به‌صورت خودکار از موتور قیمت‌گذاری محاسبه می‌شود.</span></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ذخیره کالا</button></div></form>`;
  openModal({title:product?'ویرایش کالا':'افزودن کالای جدید',subtitle:'موجودی همیشه بر اساس واحد پایه نگهداری می‌شود.',body});
}
function addInvoiceLine(productId='') {
  const holder=document.getElementById('invoice-lines');
  if(!holder) return;
  const line=document.createElement('div'); line.className='invoice-line';
  line.innerHTML=`<select data-line-product aria-label="انتخاب کالا"><option value="">انتخاب کالا</option>${db.products.map(p=>`<option value="${esc(p.id)}" ${p.id===productId?'selected':''}>${esc(p.name)} · ${esc(p.code)}</option>`).join('')}</select><input data-line-qty type="number" min="0.01" step="0.01" value="1" aria-label="مقدار" /><select data-line-unit aria-label="واحد"><option value="">واحد</option></select><span class="line-total">—</span><button class="remove-line" data-action="remove-line" aria-label="حذف ردیف">${icon('trash',14)}</button>`;
  holder.appendChild(line);
  updateLineUnits(line);
  recalcInvoiceModal();
}
function updateLineUnits(line) {
  const product=line.querySelector('[data-line-product]')?.value;
  const unitSelect=line.querySelector('[data-line-unit]');
  const p=productById(product);
  if(!unitSelect) return;
  const old=unitSelect.value;
  unitSelect.innerHTML=p?(p.units||[]).map(u=>`<option value="${esc(u.name)}" ${u.name===old?'selected':u===p.units[0]?'selected':''}>${esc(u.name)}</option>`).join(''):'<option value="">واحد</option>';
}
function invoiceModal(prefillCustomer='') {
  const roleIsCustomer=db.role==='customer';
  const customerOptions=(roleIsCustomer?db.customers.filter(c=>c.id==='c-01'):db.customers).map(c=>`<option value="${esc(c.id)}" ${c.id===prefillCustomer?'selected':''}>${esc(c.name)}</option>`).join('');
  const body=`<form id="invoice-form"><div class="form-grid"><div class="field"><label>مشتری</label><select id="inv-customer" name="customerId" required>${customerOptions}</select></div><div class="field"><label>تاریخ فاکتور (شمسی)</label><input name="date" value="${TODAY}" /></div><div class="field full"><label>روش فروش</label><div class="sale-mode-options"><div class="sale-mode-option"><input type="radio" id="mode-cash" name="mode" value="cash" checked><label for="mode-cash">${icon('wallet',14)} نقدی</label></div><div class="sale-mode-option"><input type="radio" id="mode-cheque" name="mode" value="cheque_direct"><label for="mode-cheque">${icon('cheque',14)} چک مستقیم</label></div><div class="sale-mode-option"><input type="radio" id="mode-investor" name="mode" value="investor"><label for="mode-investor">${icon('investor',14)} سرمایه‌گذار</label></div></div></div><div class="field conditional-cheque" style="display:none"><label>مدت چک (روز)</label><input id="inv-cheque-days" type="number" min="1" max="365" value="۳۰" /></div><div class="field conditional-investor" style="display:none"><label>سرمایه‌گذار</label><select id="inv-investor">${db.investors.map(i=>`<option value="${esc(i.id)}">${esc(i.name)}</option>`).join('')}</select></div><div class="field"><label>دامنه تخفیف</label><select name="discountScope" id="inv-discount-scope"><option value="per_invoice">کل فاکتور</option><option value="per_group">به تفکیک گروه کالا</option></select></div><div class="field"><label>نوع سند</label><select name="invoiceType"><option value="فروش">فاکتور فروش</option><option value="پیش‌فاکتور">پیش‌فاکتور</option></select></div></div><div class="invoice-lines"><div class="invoice-lines-head"><strong>اقلام فاکتور</strong><button type="button" class="panel-action" data-action="add-invoice-line">${icon('plus',13)}افزودن کالا</button></div><div id="invoice-lines"></div></div><div class="field" style="margin-top:8px"><label>توضیحات</label><input name="note" placeholder="توضیحات تکمیلی یا زمان تحویل" /></div><div id="invoice-summary" class="invoice-summary"></div><div class="inline-hint">${icon('shield',13)} قیمت‌ها خودکار محاسبه می‌شوند؛ برای ترکیب چند واحد از یک کالا، آن را در ردیف‌های جدا با واحد متفاوت ثبت کنید. ضریب تبدیل همان لحظه snapshot می‌شود.</div></form>`;
  const footer=`<span class="footer-note">قیمت نهایی با قوانین فعال ثبت می‌شود.</span><div class="footer-actions"><button class="btn btn-secondary" data-action="save-invoice-draft">ذخیره پیش‌نویس</button><button class="btn btn-primary" data-action="save-invoice-confirm">${icon('check',14)}تأیید و ثبت فاکتور</button></div>`;
  openModal({title:'ثبت فاکتور جدید',subtitle:'قیمت‌گذاری خودکار · ثبت واحد و ضریب تبدیل به‌صورت snapshot',body,footer,wide:true});
  addInvoiceLine();
  recalcInvoiceModal();
}
function readInvoiceCalculation() {
  const form=document.getElementById('invoice-form');
  if(!form) return {lines:[],subtotal:0,discount:0,surcharge:0,total:0,mode:'cash'};
  const customerId=form.elements.customerId.value;
  const mode=form.querySelector('[name="mode"]:checked')?.value||'cash';
  const adjustment=priceGroupAdjustment(customerId);
  let lines=[];
  [...document.querySelectorAll('#invoice-lines .invoice-line')].forEach(row=>{
    const product=productById(row.querySelector('[data-line-product]')?.value);
    const qty=Number(row.querySelector('[data-line-qty]')?.value)||0;
    const unitName=row.querySelector('[data-line-unit]')?.value;
    const unit=activeUnit(product,unitName);
    if(!product || qty<=0) return;
    const qtyBase=Number((qty*unit.factor).toFixed(3));
    const basePrice=roundedPrice(applyTomanPercent(product.baseSell,adjustment));
    const saleUnitPrice=roundedPrice(multiplyTomanByFactor(basePrice,unit.factor));
    const lineTotal=lineTomanTotal(saleUnitPrice,qty);
    lines.push({product,qty,unit,qtyBase,basePrice,saleUnitPrice,lineTotal});
    const out=row.querySelector('.line-total'); if(out) out.textContent=toman(lineTotal,false);
  });
  const subtotal=lines.reduce((s,l)=>s+l.lineTotal,0);
  let discount=0,surcharge=0;
  const discountScope=document.getElementById('inv-discount-scope')?.value||'per_invoice';
  const volumeRate=amount=>amount>=100000000?3:amount>=50000000?2:amount>=20000000?1:0;
  if(mode==='cash') {
    if(discountScope==='per_group') {
      const totals=new Map();
      lines.forEach(line=>totals.set(line.product.group,(totals.get(line.product.group)||0)+line.lineTotal));
      for(const amount of totals.values()) discount+=percentageOfToman(amount,volumeRate(amount));
    } else {
      discount=percentageOfToman(subtotal,volumeRate(subtotal));
    }
  } else {
    const days=Number(document.getElementById('inv-cheque-days')?.value)||30;
    const rate=days>=90?5:days>=60?3:days>=30?2:1;
    surcharge=percentageOfToman(subtotal,rate);
  }
  const total=subtotal-discount+surcharge;
  return {lines,subtotal,discount,surcharge,total,mode,adjustment,discountScope};
}
function recalcInvoiceModal() {
  const summary=document.getElementById('invoice-summary');
  if(!summary) return;
  const c=readInvoiceCalculation();
  summary.innerHTML=`<div class="invoice-summary-row"><span>جمع اقلام (${faNum(c.lines.length)} ردیف)</span><strong>${toman(c.subtotal)}</strong></div>${c.discount?`<div class="invoice-summary-row"><span>تخفیف حجمی نقدی · ${c.discountScope==='per_group'?'به تفکیک گروه':'کل فاکتور'}</span><strong style="color:#159878">− ${toman(c.discount)}</strong></div>`:''}${c.surcharge?`<div class="invoice-summary-row"><span>کارمزد چک / مدت ${faNum(Number(document.getElementById('inv-cheque-days')?.value)||30)} روز</span><strong style="color:#d38748">+ ${toman(c.surcharge)}</strong></div>`:''}<div class="invoice-summary-row"><span>تعدیل گروه مشتری</span><strong>${faNum(c.adjustment)}٪</strong></div><div class="invoice-summary-row total"><span>مبلغ نهایی</span><strong>${toman(c.total)}</strong></div>`;
}
function saveInvoice(status) {
  const form=document.getElementById('invoice-form');
  if(!form) return;
  const customerId=form.elements.customerId.value;
  const customer=customerById(customerId);
  const calc=readInvoiceCalculation();
  if(!customer) { toast('لطفاً مشتری را انتخاب کنید.','warning'); return; }
  if(!calc.lines.length) { toast('حداقل یک کالا به فاکتور اضافه کنید.','warning'); return; }
  const type=form.elements.invoiceType.value;
  if(status==='confirmed' && type==='فروش') {
    const shortage=calc.lines.find(l=>l.product.stockBase<l.qtyBase);
    if(shortage) {toast(`موجودی «${shortage.product.name}» برای این فاکتور کافی نیست.`,'warning');return;}
  }
  const number=`۱۴۰۵-${faNum(String(db.nextInvoice++).padStart(4,'0'))}`;
  const selectedInvestorId=document.getElementById('inv-investor')?.value||'inv-01';
  const investor=calc.mode==='investor'?(investorById(selectedInvestorId)||db.investors[0]):null;
  const itemSnapshots=calc.lines.map(l=>({productId:l.product.id,productName:l.product.name,unit:l.unit.name,quantity:l.qty,conversionFactorSnapshot:l.unit.factor,quantityInBaseUnit:l.qtyBase,unitSellPrice:l.saleUnitPrice,baseCostPrice:canSeeCost()?l.product.baseCost:undefined,lineTotal:l.lineTotal,pricingRuleSource:'pricing-profile-v1'}));
  const inv={id:`i-${Date.now()}`,number,type,customerId,customerName:customer.name,date:form.elements.date.value||TODAY,mode:modeLabel(calc.mode),modeKey:calc.mode,investorId:investor?.id||'',chequeDays:Number(document.getElementById('inv-cheque-days')?.value)||0,status,itemCount:calc.lines.length,subtotal:calc.subtotal,discount:calc.discount,surcharge:calc.surcharge,total:calc.total,note:form.elements.note.value||'',items:itemSnapshots};
  db.invoices.unshift(inv);
  if(status==='confirmed' && type==='فروش') {
    calc.lines.forEach(l=>{
      l.product.stockBase=Number((l.product.stockBase-l.qtyBase).toFixed(3));
      const movement={id:`m-${Date.now()}-${Math.random().toString(16).slice(2,6)}`,syncId:makeUuid(),productId:l.product.id,productCode:l.product.code,productName:l.product.name,warehouse:l.product.warehouse,type:'sale_out',quantityBase:l.qtyBase,unit:l.unit.name,quantity:l.qty,factor:l.unit.factor,date:inv.date,user:activeRole().name,reference:inv.number,synced:false};
      db.movements.unshift(movement); db.syncQueue.push(movement);
    });
    customer.balance+=calc.total;
  }
  if(calc.mode==='investor' && status==='confirmed' && type==='فروش') {
    const companyCost=calc.lines.reduce((s,l)=>s+lineTomanTotal(l.product.baseCost||applyTomanPercent(l.basePrice,-18),l.qtyBase),0);
    const companyItems=calc.lines.map(l=>{const cost=l.product.baseCost||applyTomanPercent(l.basePrice,-18);const companyUnitPrice=roundedPrice(multiplyTomanByFactor(applyTomanPercent(cost,10),l.unit.factor));return {...l,companyUnitPrice,companyLineTotal:lineTomanTotal(companyUnitPrice,l.qty)};});
    const companyPrice=companyItems.reduce((s,l)=>s+l.companyLineTotal,0);
    const customerPrice=calc.total;
    const dealId=`d-${Date.now()}`;
    const investorInvoice={id:`i-${Date.now()}-inv`,number:`${number}-س`,type:'فروش به سرمایه‌گذار',customerId:investor.id,customerName:investor.name,date:inv.date,mode:'نقدی',modeKey:'cash',status:'confirmed',itemCount:companyItems.length,subtotal:companyPrice,discount:0,surcharge:0,total:companyPrice,note:`معامله مرتبط با ${customer.name}`,dealId,items:companyItems.map(l=>({productId:l.product.id,productName:l.product.name,unit:l.unit.name,quantity:l.qty,conversionFactorSnapshot:l.unit.factor,quantityInBaseUnit:l.qtyBase,unitSellPrice:l.companyUnitPrice,lineTotal:l.companyLineTotal,pricingRuleSource:'investor-deal-v1'}))};
    inv.dealId=dealId;
    db.invoices.unshift(investorInvoice);
    db.deals.unshift({id:dealId,investorId:investor.id,investor:investor.name,customer:customer.name,date:inv.date,companyPrice,customerPrice,investorProfit:Math.max(0,customerPrice-companyPrice),companyCost:Math.round(companyCost),status:'open',chequeCount:1});
  }
  saveData(); closeModal(); renderApp();
  toast(status==='confirmed'?'فاکتور تأیید شد و موجودی به‌روزرسانی شد.':'پیش‌نویس فاکتور ذخیره شد.');
}
function addPurchaseLine(productId='') {
  const holder=document.getElementById('purchase-lines');if(!holder)return;
  const line=document.createElement('div');line.className='invoice-line purchase-line';
  line.innerHTML=`<select data-purchase-product aria-label="کالا"><option value="">انتخاب کالا</option>${db.products.map(p=>`<option value="${esc(p.id)}" ${p.id===productId?'selected':''}>${esc(p.name)} · ${esc(p.code)}</option>`).join('')}</select><input data-purchase-qty type="number" min="0.01" step="0.01" value="1" aria-label="مقدار"/><select data-purchase-unit aria-label="واحد"></select><input data-purchase-cost type="number" min="0" step="1" value="0" aria-label="قیمت خرید واحد"/><button class="remove-line" data-action="remove-purchase-line" aria-label="حذف ردیف">${icon('trash',14)}</button>`;
  holder.appendChild(line);updatePurchaseLine(line);recalcPurchaseModal();
}
function updatePurchaseLine(line) {
  const product=productById(line.querySelector('[data-purchase-product]')?.value);
  const select=line.querySelector('[data-purchase-unit]');if(!select)return;
  const old=select.value;
  select.innerHTML=product?(product.units||[]).map((u,index)=>`<option value="${esc(u.name)}" ${u.name===old||(!old&&index===0)?'selected':''}>${esc(u.name)}</option>`).join(''):'<option value="">واحد</option>';
  const cost=line.querySelector('[data-purchase-cost]');
  if(product&&cost)cost.value=multiplyTomanByFactor(product.baseCost,activeUnit(product,select.value).factor||1);
}
function purchaseModal(prefillSupplier='') {
  if(db.role!=='admin'){toast('ثبت فاکتور خرید فقط برای مدیر فعال است.','warning');return;}
  const body=`<form id="purchase-form"><div class="form-grid"><div class="field"><label>تأمین‌کننده</label><select name="supplierId" required>${db.suppliers.map(s=>`<option value="${esc(s.id)}" ${s.id===prefillSupplier?'selected':''}>${esc(s.name)}</option>`).join('')}</select></div><div class="field"><label>انبار مقصد</label><select name="warehouse">${db.warehouses.map(w=>`<option>${esc(w.name)}</option>`).join('')}</select></div><div class="field"><label>شماره فاکتور تأمین‌کننده</label><input name="supplierInvoice" placeholder="شماره سند خرید" /></div><div class="field"><label>تاریخ خرید (شمسی)</label><input name="date" value="${TODAY}" /></div><div class="field full"><label>نحوه پرداخت</label><select name="paymentMode"><option>نقدی</option><option>چک پرداختی</option><option>بدهی مدت‌دار</option></select></div></div><div class="invoice-lines"><div class="invoice-lines-head"><strong>اقلام خرید</strong><button type="button" class="panel-action" data-action="add-purchase-line">${icon('plus',13)}افزودن کالا</button></div><div id="purchase-lines"></div></div><div id="purchase-summary" class="invoice-summary"></div><div class="inline-hint">${icon('shield',13)}قیمت خرید محرمانه است. با تأیید فاکتور، موجودی افزایش و آخرین بهای خرید کالا به‌روزرسانی می‌شود.</div></form>`;
  const footer=`<span class="footer-note">قیمت‌ها به تومان ثبت می‌شوند.</span><div class="footer-actions"><button class="btn btn-secondary" data-action="save-purchase-draft">ذخیره پیش‌نویس</button><button class="btn btn-primary" data-action="save-purchase-confirm">${icon('check',14)}تأیید خرید و رسید</button></div>`;
  openModal({title:'ثبت فاکتور خرید',subtitle:'ثبت تأمین‌کننده، رسید انبار و به‌روزرسانی بهای آخرین خرید',body,footer,wide:true});
  addPurchaseLine();
}
function readPurchaseCalculation() {
  const lines=[];
  [...document.querySelectorAll('#purchase-lines .purchase-line')].forEach(row=>{
    const product=productById(row.querySelector('[data-purchase-product]')?.value);
    const qty=Number(row.querySelector('[data-purchase-qty]')?.value)||0;
    const unit=activeUnit(product,row.querySelector('[data-purchase-unit]')?.value);
    const unitCost=Number(row.querySelector('[data-purchase-cost]')?.value)||0;
    if(product&&qty>0)lines.push({product,qty,unit,unitCost,qtyBase:Number((qty*unit.factor).toFixed(3)),lineTotal:lineTomanTotal(unitCost,qty)});
  });
  return {lines,total:lines.reduce((sum,line)=>sum+line.lineTotal,0)};
}
function recalcPurchaseModal() {
  const summary=document.getElementById('purchase-summary');if(!summary)return;
  const calc=readPurchaseCalculation();
  summary.innerHTML=`<div class="invoice-summary-row"><span>تعداد ردیف‌های خرید</span><strong>${faNum(calc.lines.length)} ردیف</strong></div><div class="invoice-summary-row total"><span>مبلغ فاکتور خرید</span><strong>${toman(calc.total)}</strong></div>`;
}
function savePurchase(status) {
  const form=document.getElementById('purchase-form');if(!form)return;
  const supplier=db.suppliers.find(s=>s.id===form.elements.supplierId.value);
  const calc=readPurchaseCalculation();
  if(!supplier||!calc.lines.length){toast('تأمین‌کننده و حداقل یک قلم کالا را انتخاب کنید.','warning');return;}
  const number=`۱۴۰۵-${faNum(String(db.nextInvoice++).padStart(4,'0'))}`;
  const inv={id:`i-${Date.now()}`,number,type:'خرید',supplierId:supplier.id,customerId:supplier.id,customerName:supplier.name,date:form.elements.date.value||TODAY,mode:form.elements.paymentMode.value,status,itemCount:calc.lines.length,subtotal:calc.total,discount:0,surcharge:0,total:calc.total,note:`سند تأمین‌کننده: ${form.elements.supplierInvoice.value||'—'}`,items:calc.lines.map(l=>({productId:l.product.id,productName:l.product.name,unit:l.unit.name,quantity:l.qty,conversionFactorSnapshot:l.unit.factor,quantityInBaseUnit:l.qtyBase,unitSellPrice:l.unitCost,baseCostPrice:divideTomanByFactor(l.unitCost,l.unit.factor),lineTotal:l.lineTotal,pricingRuleSource:'latest-purchase'}))};
  db.invoices.unshift(inv);
  if(status==='confirmed') {
    supplier.balance+=calc.total;
    calc.lines.forEach(line=>{
      line.product.stockBase=Number((line.product.stockBase+line.qtyBase).toFixed(3));
      line.product.baseCost=divideTomanByFactor(line.unitCost,line.unit.factor);
      line.product.baseSell=roundedPrice(applyTomanPercent(line.product.baseCost,22));
      const movement={id:`m-${Date.now()}-${Math.random().toString(16).slice(2,6)}`,syncId:makeUuid(),productId:line.product.id,productCode:line.product.code,productName:line.product.name,warehouse:form.elements.warehouse.value,type:'purchase_in',quantityBase:line.qtyBase,unit:line.unit.name,quantity:line.qty,factor:line.unit.factor,date:inv.date,user:activeRole().name,reference:inv.number,synced:false};
      db.movements.unshift(movement);db.syncQueue.push(movement);
    });
    inv.stockPosted=true;
  }
  saveData();closeModal();renderApp();toast(status==='confirmed'?'فاکتور خرید تأیید شد؛ موجودی و بهای کالا به‌روزرسانی شد.':'پیش‌نویس فاکتور خرید ذخیره شد.');
}
function confirmInvoiceRecord(id) {
  const inv=db.invoices.find(i=>i.id===id);
  if(!inv||inv.status!=='draft')return;
  if(inv.type==='خرید'&&db.role!=='admin'){toast('تأیید فاکتور خرید فقط برای مدیر فعال است.','warning');return;}
  if(inv.type==='خرید'&&inv.items?.length&&!inv.stockPosted) {
    const supplier=db.suppliers.find(s=>s.id===inv.supplierId);
    inv.items.forEach(item=>{const product=productById(item.productId);if(!product)return;product.stockBase=Number((product.stockBase+item.quantityInBaseUnit).toFixed(3));product.baseCost=Number.isFinite(item.baseCostPrice)?item.baseCostPrice:divideTomanByFactor(item.unitSellPrice,item.conversionFactorSnapshot);product.baseSell=roundedPrice(applyTomanPercent(product.baseCost,22));const movement={id:`m-${Date.now()}-${Math.random().toString(16).slice(2,6)}`,syncId:makeUuid(),productId:product.id,productCode:product.code,productName:product.name,warehouse:product.warehouse,type:'purchase_in',quantityBase:item.quantityInBaseUnit,unit:item.unit,quantity:item.quantity,factor:item.conversionFactorSnapshot,date:inv.date,user:activeRole().name,reference:inv.number,synced:false};db.movements.unshift(movement);db.syncQueue.push(movement);});
    if(supplier)supplier.balance+=inv.total;
    inv.stockPosted=true;
  }
  if(inv.type==='فروش'&&inv.items?.length&&!inv.stockPosted) {
    const lines=inv.items.map(item=>({item,product:productById(item.productId)}));
    const shortage=lines.find(line=>line.product&&line.product.stockBase<line.item.quantityInBaseUnit);
    if(shortage){toast(`موجودی «${shortage.product.name}» برای تأیید فاکتور کافی نیست.`,'warning');return;}
    lines.forEach(({item,product})=>{
      if(!product)return;
      product.stockBase=Number((product.stockBase-item.quantityInBaseUnit).toFixed(3));
      const movement={id:`m-${Date.now()}-${Math.random().toString(16).slice(2,6)}`,syncId:makeUuid(),productId:product.id,productCode:product.code,productName:product.name,warehouse:product.warehouse,type:'sale_out',quantityBase:item.quantityInBaseUnit,unit:item.unit,quantity:item.quantity,factor:item.conversionFactorSnapshot,date:inv.date,user:activeRole().name,reference:inv.number,synced:false};
      db.movements.unshift(movement);db.syncQueue.push(movement);
    });
    const customer=customerById(inv.customerId);if(customer)customer.balance+=inv.total;
    inv.stockPosted=true;
    if(inv.modeKey==='investor'&&!inv.dealId) {
      const investor=investorById(inv.investorId)||db.investors[0];
      const companyCost=lines.reduce((sum,line)=>sum+lineTomanTotal(line.product?.baseCost||applyTomanPercent(line.item.unitSellPrice||0,-18),line.item.quantityInBaseUnit),0);
      const companyItems=lines.map(line=>{const cost=line.product?.baseCost||applyTomanPercent(line.item.unitSellPrice||0,-18);const price=roundedPrice(multiplyTomanByFactor(applyTomanPercent(cost,10),line.item.conversionFactorSnapshot));return {product:line.product,item:line.item,price,total:lineTomanTotal(price,line.item.quantity)};});
      const companyPrice=companyItems.reduce((sum,line)=>sum+line.total,0);
      const dealId=`d-${Date.now()}`;
      const investorInvoice={id:`i-${Date.now()}-inv`,number:`${inv.number}-س`,type:'فروش به سرمایه‌گذار',customerId:investor.id,customerName:investor.name,date:inv.date,mode:'نقدی',modeKey:'cash',status:'confirmed',itemCount:companyItems.length,subtotal:companyPrice,discount:0,surcharge:0,total:companyPrice,note:`معامله مرتبط با ${customer?.name||''}`,dealId,items:companyItems.map(line=>({productId:line.product?.id,productName:line.product?.name||line.item.productName,unit:line.item.unit,quantity:line.item.quantity,conversionFactorSnapshot:line.item.conversionFactorSnapshot,quantityInBaseUnit:line.item.quantityInBaseUnit,unitSellPrice:line.price,lineTotal:line.total,pricingRuleSource:'investor-deal-v1'}))};
      inv.dealId=dealId;db.invoices.unshift(investorInvoice);
      db.deals.unshift({id:dealId,investorId:investor.id,investor:investor.name,customer:customer?.name||inv.customerName,date:inv.date,companyPrice,customerPrice:inv.total,investorProfit:Math.max(0,inv.total-companyPrice),companyCost:Math.round(companyCost),status:'open',chequeCount:1});
    }
  }
  inv.status='confirmed';saveData();renderApp();toast(inv.type==='فروش'?'فاکتور تأیید شد؛ موجودی و حساب مشتری به‌روزرسانی شد.':inv.type==='خرید'?'فاکتور خرید تأیید شد؛ موجودی و بهای کالا به‌روزرسانی شد.':'پیش‌فاکتور تأیید شد؛ موجودی تغییر نکرد.');
}
function movementModal(prefillType='') {
  const body=`<form id="movement-form" class="form-grid"><div class="field"><label id="movement-warehouse-label">انبار</label><select name="warehouse">${db.warehouses.map(w=>`<option>${esc(w.name)}</option>`).join('')}</select></div><div class="field"><label>نوع گردش</label><select name="type" id="movement-type"><option value="purchase_in">رسید کالا / خرید</option><option value="sale_out">حواله خروج</option><option value="transfer_in">انتقال ورودی</option><option value="transfer_out">انتقال خروجی</option><option value="adjustment">اصلاح موجودی / شمارش</option></select></div><div class="field full"><label>کالا</label><select name="productId" required>${db.products.map(p=>`<option value="${esc(p.id)}">${esc(p.name)} · ${esc(p.code)} · ${stockText(p)}</option>`).join('')}</select></div><div class="field"><label>مقدار</label><input name="quantity" type="number" step="0.01" min="0.01" value="1" required /></div><div class="field"><label>واحد ثبت</label><select name="unit" id="movement-unit"></select></div><div class="field" id="adjustment-field" style="display:none"><label>جهت اصلاح</label><select name="adjustmentSign"><option value="1">افزایش موجودی</option><option value="-1">کاهش موجودی</option></select></div><div class="field" id="destination-field" style="display:none"><label id="movement-destination-label">انبار مقصد</label><select name="destinationWarehouse">${db.warehouses.map(w=>`<option>${esc(w.name)}</option>`).join('')}</select></div><div class="field"><label>سند مرجع (اختیاری)</label><input name="reference" placeholder="شماره فاکتور یا حواله" /></div><div class="field full"><span class="field-hint">موجودی بر اساس واحد پایه محاسبه و ضریب تبدیل فعلی در سابقه سند ذخیره می‌شود.</span></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ثبت گردش انبار</button></div></form>`;
  openModal({title:'ثبت گردش کالا',subtitle:'امکان ثبت و ذخیره محلی در حالت آفلاین',body});
  const f=document.querySelector('#movement-form');
  if(prefillType) { f.elements.type.value=prefillType; f.elements.type.dispatchEvent(new Event('change',{bubbles:true})); }
  updateMovementUnits();
}
function updateMovementUnits() {
  const form=document.getElementById('movement-form'); if(!form) return;
  const p=productById(form.elements.productId.value);
  const select=document.getElementById('movement-unit');
  select.innerHTML=(p?.units||[]).map(u=>`<option value="${esc(u.name)}">${esc(u.name)} · ضریب ${numberString(u.factor)}</option>`).join('');
}
function makeUuid() {
  if(globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g,c=>{const r=Math.random()*16|0;return(c==='x'?r:(r&3|8)).toString(16);});
}
function saveMovement(form) {
  const product=productById(form.elements.productId.value);
  const unit=activeUnit(product,form.elements.unit.value);
  const quantity=Number(form.elements.quantity.value);
  const type=form.elements.type.value;
  if(!product||quantity<=0) {toast('کالا و مقدار معتبر را وارد کنید.','warning');return;}
  const quantityBase=Number((quantity*unit.factor).toFixed(3));
  const transfer=type==='transfer_in'||type==='transfer_out';
  const selectedWarehouse=form.elements.warehouse.value;
  const selectedOtherWarehouse=form.elements.destinationWarehouse?.value||'';
  if(transfer&&(!selectedOtherWarehouse||selectedWarehouse===selectedOtherWarehouse)){toast('برای انتقال، دو انبار متفاوت انتخاب کنید.','warning');return;}
  const sourceWarehouse=type==='transfer_in'?selectedOtherWarehouse:selectedWarehouse;
  const destinationWarehouse=type==='transfer_in'?selectedWarehouse:selectedOtherWarehouse;
  const sign=['purchase_in','transfer_in'].includes(type)?1:['sale_out','transfer_out'].includes(type)?-1:type==='adjustment'?Number(form.elements.adjustmentSign.value):1;
  if(sign<0 && product.stockBase<quantityBase) {toast('موجودی این کالا برای خروج یا اصلاح کاهشی کافی نیست.','warning');return;}
  if(!transfer)product.stockBase=Number((product.stockBase+sign*quantityBase).toFixed(3));
  const movement={id:`m-${Date.now()}`,syncId:makeUuid(),productId:product.id,productCode:product.code,productName:product.name,warehouse:transfer?sourceWarehouse:selectedWarehouse,destinationWarehouse:transfer?destinationWarehouse:'',type,quantityBase,unit:unit.name,quantity,factor:unit.factor,direction:sign<0?'decrease':'increase',date:form.elements.date?.value||TODAY,user:activeRole().name,reference:form.elements.reference.value||'—',synced:false};
  db.movements.unshift(movement); db.syncQueue.push(movement);
  saveData(); closeModal(); renderApp();
  toast(navigator.onLine?'گردش ثبت شد و در صف همگام‌سازی قرار گرفت.':'گردش به‌صورت آفلاین روی دستگاه ذخیره شد.');
  trySyncQueue();
}
function addChequeModal() {
  const body=`<form id="cheque-form" class="form-grid"><div class="field"><label>نوع چک</label><select name="type"><option>دریافتی</option><option>پرداختی</option></select></div><div class="field"><label>شماره چک</label><input name="number" required /></div><div class="field"><label>بانک</label><input name="bank" required placeholder="نام بانک" /></div><div class="field"><label>مبلغ (تومان)</label><input name="amount" type="number" min="1" required /></div><div class="field"><label>طرف حساب</label><input name="party" required /></div><div class="field"><label>تاریخ سررسید (شمسی)</label><input name="due" placeholder="۱۴۰۵/۰۷/۲۰" required /></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ثبت چک</button></div></form>`;
  openModal({title:'ثبت چک جدید',subtitle:'دریافتی از مشتری یا پرداختی به تأمین‌کننده',body});
}
function accountModal(id) {
  const c=customerById(id);
  if(!c) return;
  const invoices=db.invoices.filter(i=>i.customerId===id);
  const body=`<div class="deal-card-top"><div class="cell-main"><div class="cell-avatar" style="width:40px;height:40px">${esc(shortName(c.name))}</div><div><strong class="cell-title">${esc(c.name)}</strong><span class="cell-sub">${esc(c.phone)} · ${esc(c.group)}</span></div></div><span class="type-badge">${esc(c.type)}</span></div><div class="summary-strip" style="margin-top:16px"><div class="card summary-tile"><span>مانده حساب</span><strong>${toman(c.balance)}</strong></div><div class="card summary-tile"><span>سقف اعتبار</span><strong>${toman(c.limit)}</strong></div></div><h3 style="font-size:10px;color:#58637b;margin:17px 0 8px">فاکتورهای اخیر</h3><div class="table-scroll"><table><thead><tr><th>شماره</th><th>تاریخ</th><th>مبلغ</th><th>وضعیت</th></tr></thead><tbody>${invoices.length?invoices.slice(0,5).map(i=>`<tr><td>${esc(i.number)}</td><td>${esc(i.date)}</td><td>${toman(i.total)}</td><td><span class="status ${statusClass(i.status)}">${statusLabel(i.status)}</span></td></tr>`).join(''):`<tr><td colspan="4">هنوز فاکتوری ثبت نشده است.</td></tr>`}</tbody></table></div><div class="inline-hint">${icon('shield',13)}قیمت خرید تأمین‌کننده در گردش حساب مشتری نمایش داده نمی‌شود.</div>`;
  const footer=`<span class="footer-note">گروه قیمت: ${esc(c.group)}</span><div class="footer-actions"><button class="btn btn-secondary" data-action="payment-modal" data-id="${esc(c.id)}">ثبت دریافت</button><button class="btn btn-primary" data-action="customer-invoice" data-id="${esc(c.id)}">${icon('plus',14)}فاکتور جدید</button></div>`;
  openModal({title:'حساب مشتری',subtitle:esc(c.code),body,footer,wide:true});
}
function invoiceDetails(id) {
  const inv=db.invoices.find(i=>i.id===id); if(!inv) return;
  if(inv.type==='خرید'&&db.role!=='admin'){toast('جزئیات بهای خرید فقط برای مدیر مجاز است.','warning');return;}
  const items=inv.items||[];
  const body=`<div class="summary-strip"><div class="card summary-tile"><span>شماره فاکتور</span><strong>${esc(inv.number)}</strong></div><div class="card summary-tile"><span>مشتری</span><strong style="font-size:11px">${esc(inv.customerName)}</strong></div><div class="card summary-tile"><span>تاریخ</span><strong style="font-size:11px">${esc(inv.date)}</strong></div><div class="card summary-tile"><span>وضعیت</span><strong style="font-size:11px"><span class="status ${statusClass(inv.status)}">${statusLabel(inv.status)}</span></strong></div></div><div class="table-scroll"><table><thead><tr><th>کالا</th><th>مقدار</th><th>واحد</th><th>ضریب ذخیره‌شده</th><th>${inv.type==='خرید'?'قیمت خرید واحد':'قیمت فروش واحد'}</th><th>مبلغ</th></tr></thead><tbody>${items.length?items.map(i=>`<tr><td>${esc(i.productName)}</td><td>${numberString(i.quantity)}</td><td>${esc(i.unit)}</td><td>${numberString(i.conversionFactorSnapshot)}</td><td>${canSeeMoney()?toman(i.unitSellPrice):'—'}</td><td>${canSeeMoney()?toman(i.lineTotal):'—'}</td></tr>`).join(''):`<tr><td colspan="6">اقلام نمایشی فاکتور قدیمی در این نسخه نگهداری نشده‌اند.</td></tr>`}</tbody></table></div>${canSeeMoney()?`<div class="invoice-summary"><div class="invoice-summary-row"><span>جمع کالاها</span><strong>${toman(inv.subtotal)}</strong></div><div class="invoice-summary-row"><span>تخفیف</span><strong>${toman(inv.discount)}</strong></div><div class="invoice-summary-row"><span>کارمزد</span><strong>${toman(inv.surcharge)}</strong></div><div class="invoice-summary-row total"><span>مبلغ نهایی · ${esc(modeLabel(inv.mode))}</span><strong>${toman(inv.total)}</strong></div></div>`:''}<div class="inline-hint">${icon('shield',13)} قیمت فروش و ضریب تبدیل در زمان ثبت روی سند snapshot شده‌اند و با تغییر قوانین قیمت‌گذاری تغییر نمی‌کنند.</div>`;
  openModal({title:'جزئیات فاکتور',subtitle:`${esc(inv.number)} · ${esc(inv.type)}`,body,footer:`<span class="footer-note">${esc(inv.note||'بدون توضیحات')}</span><div class="footer-actions"><button class="btn btn-secondary" data-action="print-invoice" data-id="${esc(inv.id)}">${icon('printer',14)}چاپ</button><button class="btn btn-primary" data-action="close-modal">بستن</button></div>`,wide:true});
}
function chequeDetails(id) {
  const ch=db.cheques.find(c=>c.id===id); if(!ch)return;
  const body=`<div class="summary-strip"><div class="card summary-tile"><span>شماره چک</span><strong>${esc(ch.number)}</strong></div><div class="card summary-tile"><span>مبلغ</span><strong>${toman(ch.amount)}</strong></div></div><div class="settings-row"><div><strong>طرف حساب</strong><span>${esc(ch.party)}</span></div><span class="type-badge">${esc(ch.type)}</span></div><div class="settings-row"><div><strong>بانک</strong><span>${esc(ch.bank)}</span></div><span class="status ${statusClass(ch.status)}">${statusLabel(ch.status)}</span></div><div class="settings-row"><div><strong>تاریخ سررسید</strong><span>${esc(ch.due)}</span></div><div><strong>دارنده</strong><span>${esc(ch.holder)}</span></div></div>`;
  openModal({title:'جزئیات چک',subtitle:'مدیریت گردش و پیگیری سررسید',body,footer:`<span class="footer-note">${esc(ch.type)}</span><div class="footer-actions"><button class="btn btn-secondary" data-action="cycle-cheque" data-id="${esc(ch.id)}">تغییر وضعیت</button><button class="btn btn-primary" data-action="close-modal">بستن</button></div>`});
}
function alertsModal() {
  const due=db.cheques.filter(ch=>ch.status==='in_hand'||ch.status==='bounced');
  const low=db.products.filter(p=>p.stockBase<=p.minStock);
  const body=`<div class="low-stock-list">${due.slice(0,4).map(ch=>`<div class="low-stock-item"><div class="product-thumb ${ch.status==='bounced'?'':'orange'}">${icon(ch.status==='bounced'?'alert':'cheque',17)}</div><div class="low-stock-meta"><strong>${ch.status==='bounced'?'چک برگشتی':'سررسید چک'} · ${esc(ch.party)}</strong><span>${esc(ch.number)} · ${esc(ch.due)}</span></div><div class="stock-remaining"><strong style="font-size:10px">${toman(ch.amount,false)}</strong><span>تومان</span></div></div>`).join('')}${low.slice(0,3).map(p=>`<div class="low-stock-item"><div class="product-thumb orange">${icon('box',17)}</div><div class="low-stock-meta"><strong>موجودی کم · ${esc(p.name)}</strong><span>موجودی ${stockText(p)}</span></div><div class="stock-remaining"><strong>${numberString(p.stockBase)}</strong><span>${esc(p.baseUnit)}</span></div></div>`).join('')}</div>`;
  openModal({title:'اعلان‌ها',subtitle:`${faNum(due.length+low.length)} مورد نیازمند پیگیری`,body,footer:`<button class="btn btn-secondary" data-action="close-modal">بستن</button>`});
}
function paymentModal(customerId) {
  const c=customerById(customerId);
  const body=`<form id="payment-form" class="form-grid"><input type="hidden" name="customerId" value="${esc(customerId)}"/><div class="field"><label>مشتری</label><input readonly value="${esc(c?.name||'مشتری')}"/></div><div class="field"><label>روش پرداخت</label><select name="type"><option>نقدی</option><option>کارت</option><option>چک</option></select></div><div class="field"><label>مبلغ (تومان)</label><input name="amount" type="number" min="1" required/></div><div class="field"><label>تاریخ دریافت (شمسی)</label><input name="date" value="${TODAY}"/></div><div class="field full"><label>توضیحات</label><input name="note" placeholder="شماره پیگیری، توضیح یا شماره فاکتور"/></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ثبت دریافت</button></div></form>`;
  openModal({title:'ثبت دریافت از مشتری',subtitle:'ثبت پرداخت در گردش حساب',body});
}
function addDealModal() {
  const body=`<form id="deal-form" class="form-grid"><div class="field"><label>سرمایه‌گذار</label><select name="investorId">${db.investors.map(i=>`<option value="${esc(i.id)}">${esc(i.name)}</option>`).join('')}</select></div><div class="field"><label>مشتری نهایی</label><select name="customerId">${db.customers.map(c=>`<option value="${esc(c.id)}">${esc(c.name)}</option>`).join('')}</select></div><div class="field"><label>قیمت فروش بنفشه به سرمایه‌گذار</label><input name="companyPrice" type="number" min="0" required/></div><div class="field"><label>قیمت فروش به مشتری</label><input name="customerPrice" type="number" min="0" required/></div><div class="field"><label>تعداد چک</label><input name="chequeCount" type="number" min="0" value="1"/></div><div class="field"><label>تاریخ معامله (شمسی)</label><input name="date" value="${TODAY}"/></div>${canSeeCost()?`<div class="field full"><label>بهای خرید بنفشه از تأمین‌کننده (فقط مدیر)</label><input name="companyCost" type="number" min="0" required/></div>`:''}<div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ثبت معامله</button></div></form>`;
  openModal({title:'ثبت معامله سرمایه‌گذاری',subtitle:'ثبت دوطرفه فروش و سهم سود سرمایه‌گذار',body});
}
function settlementModal() {
  const body=`<form id="settlement-form" class="form-grid"><div class="field"><label>سرمایه‌گذار</label><select name="investorId">${db.investors.map(i=>`<option value="${esc(i.id)}">${esc(i.name)}</option>`).join('')}</select></div><div class="field"><label>نوع تسویه</label><select name="type"><option>نقدی</option><option>کالا</option><option>چک</option></select></div><div class="field"><label>مبلغ / ارزش تسویه (تومان)</label><input name="amount" type="number" min="1" required/></div><div class="field"><label>تاریخ (شمسی)</label><input name="date" value="${TODAY}"/></div><div class="field full"><label>توضیحات</label><input name="note"/></div><div class="field full"><button class="btn btn-primary" type="submit">${icon('check',14)}ثبت تسویه</button></div></form>`;
  openModal({title:'ثبت تسویه سرمایه‌گذار',subtitle:'تسویه نقدی، کالا یا چک',body});
}

function bindPwa() {
  if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
    navigator.serviceWorker.register('./sw.js').catch(err=>console.info('PWA worker unavailable',err));
  }
}
async function trySyncQueue() {
  if (!navigator.onLine || !db.settings.pbUrl || !db.syncQueue.length || !db.pbToken) return;
  const base=db.settings.pbUrl.replace(/\/$/,'');
  db.deviceId ||= `device-${makeUuid()}`;
  let changed=false, failed=false, conflictCount=0;
  for (const pending of [...db.syncQueue]) {
    try {
      const filter=encodeURIComponent(`sync_id = '${pending.syncId}'`);
      const headers={Authorization:db.pbToken};
      const getQueue=async()=>{
        const response=await fetch(`${base}/api/collections/sync_queue/records?filter=${filter}&perPage=1`,{headers});
        if(!response.ok)throw new Error('PocketBase sync queue is not accessible.');
        return (await response.json()).items||[];
      };
      let serverRows=await getQueue();
      if(!serverRows.length) {
        const body={device_id:db.deviceId,user_id:db.pbUserId,entity_type:'stock_movement',entity_id:pending.id,action:'create',payload:{...pending,clientTimestamp:pending.clientTimestamp||new Date().toISOString()},sync_id:pending.syncId,synced_at:''};
        const response=await fetch(`${base}/api/collections/sync_queue/records`,{method:'POST',headers:{...headers,'Content-Type':'application/json'},body:JSON.stringify(body)});
        if(!response.ok)throw new Error('PocketBase rejected an offline stock movement.');
        serverRows=await getQueue();
      }
      let serverRecord=serverRows[0];
      if(!serverRecord?.synced_at&&serverRecord?.id) {
        const retry=await fetch(`${base}/api/benafsheh/sync-queue/${encodeURIComponent(serverRecord.id)}/retry`,{method:'POST',headers});
        if(retry.ok||retry.status===409){serverRows=await getQueue();serverRecord=serverRows[0];}
      }
      if(!serverRecord?.synced_at) { pending.syncError=serverRecord?.error_message||'ثبت روی سرور در انتظار بررسی است.';failed=true;break; }
      if(serverRecord.conflict)conflictCount++;
      db.syncQueue=db.syncQueue.filter(q=>q.syncId!==pending.syncId);
      const local=db.movements.find(m=>m.syncId===pending.syncId); if(local)local.synced=true;
      changed=true;
    } catch(err) { pending.syncError=err.message;failed=true;break; }
  }
  if(changed) { db.settings.lastSync=TODAY+'، '+faNum(new Date().toTimeString().slice(0,5)); saveData(); if(db.loggedIn)renderApp(); }
  if(conflictCount)toast(`${faNum(conflictCount)} عملیات با زمان ثبت سرور همگام شد؛ لطفاً موارد را بررسی کنید.`,'warning');
  if(failed) {saveData();toast('همگام‌سازی کامل نشد؛ عملیات در صف دستگاه باقی ماند.','warning');}
}
window.addEventListener('online',()=>{toast('اتصال اینترنت برقرار شد.','success');trySyncQueue();if(db.loggedIn)renderApp();});
window.addEventListener('offline',()=>{toast('اتصال اینترنت قطع شد؛ اطلاعات محلی در دسترس است.','warning');if(db.loggedIn)renderApp();});

// Event delegation keeps all views functional after each role/page render.
document.addEventListener('click', event => {
  if(event.target.id==='sidebarOverlay') { document.getElementById('sidebar')?.classList.remove('open'); event.target.classList.remove('open'); return; }
  const nav=event.target.closest('[data-nav]');
  if(nav) { db.activePage=nav.dataset.nav; globalSearch=''; saveData(); renderApp(); document.getElementById('sidebar')?.classList.remove('open'); document.getElementById('sidebarOverlay')?.classList.remove('open'); return; }
  const roleButton=event.target.closest('[data-role]');
  if(roleButton) { db.role=roleButton.dataset.role; db.pbToken=''; db.pbUserId=''; db.serverUserName=''; db.activePage='dashboard'; saveData(); closeModal(); renderApp(); toast(`نمایش نقش «${roleInfo[db.role].label}» فعال شد.`); return; }
  const filter=event.target.closest('[data-invoice-filter]');
  if(filter) { currentInvoiceFilter=filter.dataset.invoiceFilter; renderApp(); return; }
  const group=event.target.closest('[data-product-group]');
  if(group) { currentProductGroup=group.dataset.productGroup; renderApp(); return; }
  const action=event.target.closest('[data-action]');
  if(!action) { if(event.target.matches('[data-backdrop]'))closeModal(); return; }
  const id=action.dataset.id;
  switch(action.dataset.action) {
    case 'close-modal': closeModal(); break;
    case 'toggle-menu': document.getElementById('sidebar')?.classList.toggle('open'); document.getElementById('sidebarOverlay')?.classList.toggle('open'); break;
    case 'open-role': roleModal(); break;
    case 'logout': db.loggedIn=false; db.pbToken=''; db.pbUserId=''; db.serverUserName=''; saveData(); renderApp(); break;
    case 'create-invoice': invoiceModal(); break;
    case 'customer-invoice': closeModal(); invoiceModal(id); break;
    case 'add-invoice-line': addInvoiceLine(); break;
    case 'remove-line': action.closest('.invoice-line')?.remove(); recalcInvoiceModal(); break;
    case 'add-purchase-line': addPurchaseLine(); break;
    case 'remove-purchase-line': action.closest('.purchase-line')?.remove(); recalcPurchaseModal(); break;
    case 'save-purchase-draft': savePurchase('draft'); break;
    case 'save-purchase-confirm': savePurchase('confirmed'); break;
    case 'save-invoice-draft': saveInvoice('draft'); break;
    case 'save-invoice-confirm': saveInvoice('confirmed'); break;
    case 'add-customer': customerModal(); break;
    case 'add-supplier': supplierModal(); break;
    case 'supplier-purchases': closeModal(); purchaseModal(id); break;
    case 'create-purchase': purchaseModal(); break;
    case 'add-product': productModal(); break;
    case 'product-details': { const p=productById(id); if(p)openModal({title:esc(p.name),subtitle:esc(p.code)+' · '+esc(p.group),body:`<div class="summary-strip"><div class="card summary-tile"><span>موجودی فعلی</span><strong>${stockText(p)}</strong></div><div class="card summary-tile"><span>واحد پایه</span><strong>${esc(p.baseUnit)}</strong></div></div><h3 style="font-size:10px;color:#58637b">واحدهای فروش و ضریب تبدیل</h3><div class="table-scroll"><table><thead><tr><th>واحد فروش</th><th>ضریب تبدیل</th><th>نسخه</th></tr></thead><tbody>${p.units.map(u=>`<tr><td>${esc(u.name)}</td><td>${numberString(u.factor)} ${esc(p.baseUnit)}</td><td>${u.version?faNum(u.version):'فعال'}</td></tr>`).join('')}</tbody></table></div>${canSeeCost()?`<div class="inline-hint">قیمت خرید محرمانه این کالا: ${toman(p.baseCost)} / ${esc(p.baseUnit)}</div>`:''}`,footer:`<button class="btn btn-secondary" data-action="close-modal">بستن</button>`});break; }
    case 'customer-account': accountModal(id); break;
    case 'invoice-details': invoiceDetails(id); break;
    case 'cheque-details': chequeDetails(id); break;
    case 'create-movement': movementModal(); break;
    case 'inventory-count': movementModal('adjustment'); break;
    case 'add-cheque': addChequeModal(); break;
    case 'add-deal': addDealModal(); break;
    case 'settlement': settlementModal(); break;
    case 'payment-modal': paymentModal(id); break;
    case 'alerts': alertsModal(); break;
    case 'sync-now': trySyncQueue().then(()=>{if(!db.settings.pbUrl)toast('برای همگام‌سازی سرور، ابتدا نشانی PocketBase را در تنظیمات وارد کنید.','warning');else if(!db.pbToken)toast('اتصال امن PocketBase نیازمند ورود کاربری معتبر است.','warning');else if(!db.syncQueue.length)toast('همه عملیات همگام هستند.');}); break;
    case 'cycle-cheque': { const cheque=db.cheques.find(c=>c.id===id);if(cheque){const order=['in_hand','deposited','cleared','bounced','transferred'];cheque.status=order[(order.indexOf(cheque.status)+1)%order.length];saveData();renderApp();chequeDetails(id);toast(`وضعیت چک به «${statusLabel(cheque.status)}» تغییر کرد.`);}break; }
    case 'print-invoice': window.print(); break;
    case 'confirm-invoice': confirmInvoiceRecord(id); break;
    case 'export-invoices': {const invoices=db.role==='customer'?db.invoices.filter(i=>i.customerId==='c-01'):db.role==='admin'?db.invoices:db.invoices.filter(i=>!['خرید','برگشت از خرید'].includes(i.type));downloadCSV('فاکتورهای-بنفشه.csv',[['شماره','مشتری','تاریخ','روش','وضعیت','مبلغ'],...invoices.map(i=>[i.number,i.customerName,i.date,i.mode,statusLabel(i.status),i.total])]);toast('فایل CSV سازگار با Excel آماده شد.');break;}
    case 'export-cheques': {const cheques=db.role==='investor'?db.cheques.filter(c=>c.holder==='سرمایه‌گذار'&&c.investorId==='inv-01'):db.cheques;downloadCSV('چک‌های-بنفشه.csv',[['شماره','بانک','طرف حساب','نوع','سررسید','مبلغ','وضعیت'],...cheques.map(c=>[c.number,c.bank,c.party,c.type,c.due,c.amount,statusLabel(c.status)])]);toast('فایل CSV سازگار با Excel آماده شد.');break;}
    case 'export-report': downloadCSV('گزارش-بنفشه.csv',[['گروه','مقدار'],['فروش ناخالص',326480000],['فاکتور فروش',128],['مبلغ مرجوعی',6240000],['موجودی کالا',db.products.length]]);toast('گزارش CSV آماده شد.');break;
    case 'download-template': downloadTemplate(action.dataset.template); break;
    case 'import-template': {const input=document.getElementById('import-file');if(input){input.dataset.template=action.dataset.template||'products';input.click();}break;}
    case 'toggle-offline': db.settings.offlineMode=!db.settings.offlineMode;saveData();renderApp();toast(`ذخیره آفلاین ${db.settings.offlineMode?'فعال':'غیرفعال'} شد.`);break;
    case 'add-warehouse': toast('مدیریت انبارها از نسخه پایه در دسترس است.','warning');break;
    case 'clear-local': if(confirm('داده‌های نمایشی محلی پاک و نسخه اولیه بازیابی شود؟')){localStorage.removeItem(STORAGE_KEY);db=clone(initialData);saveData();renderApp();toast('داده‌های آزمایشی بازیابی شدند.');}break;
    case 'investor-report': toast('این گزارش فقط برای مدیر سیستم در دسترس است.');break;
  }
});
document.addEventListener('change', event => {
  if(event.target.matches('#invoice-form [name="mode"]')) {
    const mode=event.target.value;
    document.querySelectorAll('.conditional-cheque').forEach(el=>el.style.display=mode==='cash'?'none':'flex');
    document.querySelectorAll('.conditional-investor').forEach(el=>el.style.display=mode==='investor'?'flex':'none');
    recalcInvoiceModal(); return;
  }
  if(event.target.matches('#inv-cheque-days')) {recalcInvoiceModal();return;}
  if(event.target.matches('[data-line-product]')) {updateLineUnits(event.target.closest('.invoice-line'));recalcInvoiceModal();return;}
  if(event.target.matches('[data-line-unit],[data-line-qty],#inv-customer,#inv-discount-scope')) {recalcInvoiceModal();return;}
  if(event.target.matches('#movement-form [name="productId"]')) {updateMovementUnits();return;}
  if(event.target.matches('[data-purchase-product]')) {updatePurchaseLine(event.target.closest('.purchase-line'));recalcPurchaseModal();return;}
  if(event.target.matches('[data-purchase-unit],[data-purchase-qty],[data-purchase-cost]')) {recalcPurchaseModal();return;}
  if(event.target.matches('#movement-type')) {
    const type=event.target.value;
    const adjustment=document.getElementById('adjustment-field');
    const destination=document.getElementById('destination-field');
    const warehouseLabel=document.getElementById('movement-warehouse-label');
    const destinationLabel=document.getElementById('movement-destination-label');
    const transfer=type.startsWith('transfer_');
    if(adjustment)adjustment.style.display=type==='adjustment'?'flex':'none';
    if(destination)destination.style.display=transfer?'flex':'none';
    if(warehouseLabel)warehouseLabel.textContent=transfer?(type==='transfer_in'?'انبار مقصد':'انبار مبدأ'):'انبار';
    if(destinationLabel)destinationLabel.textContent=type==='transfer_in'?'انبار مبدأ':'انبار مقصد';
    return;
  }
  if(event.target.matches('#global-search')) { globalSearch=event.target.value.trim();saveData();return; }
  if(event.target.matches('[data-local-search]')) {globalSearch=event.target.value.trim();const pos=event.target.selectionStart;renderApp();const newInput=document.querySelector('[data-local-search]');if(newInput){newInput.focus();newInput.setSelectionRange(pos,pos);}return;}
});
document.addEventListener('input', event => {
  if(event.target.matches('#global-search')) { globalSearch=event.target.value.trim(); }
  if(event.target.matches('[data-local-search]')) {
    globalSearch=event.target.value.trim();
    const selector=event.target.id?`#${event.target.id}`:'[data-local-search]';
    const position=event.target.selectionStart;
    renderApp();
    const replacement=document.querySelector(selector);
    if(replacement){replacement.focus();replacement.setSelectionRange(position,position);}
    return;
  }
  if(event.target.matches('#invoice-form [data-line-qty]')) recalcInvoiceModal();
  if(event.target.matches('[data-purchase-qty],[data-purchase-cost]')) recalcPurchaseModal();
});
document.addEventListener('keydown', event => {
  if(event.key==='Enter' && event.target.matches('#global-search')) {
    event.preventDefault(); globalSearch=event.target.value.trim();
    if(!globalSearch)return;
    const foundProduct=db.products.some(p=>`${p.name} ${p.code}`.toLowerCase().includes(globalSearch.toLowerCase()));
    const foundCustomer=db.customers.some(c=>`${c.name} ${c.phone}`.toLowerCase().includes(globalSearch.toLowerCase()));
    db.activePage=foundProduct?'products':foundCustomer?'customers':'invoices';
    renderApp();
  }
});
document.addEventListener('submit', async event => {
  if(event.target.id==='login-form') {
    event.preventDefault();
    const identity=document.getElementById('login-phone').value.trim();
    const password=document.getElementById('login-password').value;
    const base=(db.settings.pbUrl||'').replace(/\/$/,'');
    if(base&&identity&&password) {
      try {
        const response=await fetch(`${base}/api/collections/users/auth-with-password`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({identity,password})});
        const result=await response.json();
        if(!response.ok) throw new Error(result?.message||'نام کاربری یا گذرواژه نادرست است.');
        if(result.record?.is_active===false) throw new Error('حساب کاربری غیرفعال است.');
        db.pbToken=result.token;db.pbUserId=result.record.id;db.role=roleInfo[result.record.role]?result.record.role:'sales';db.loggedIn=true;db.activePage='dashboard';
        db.serverUserName=result.record.name||'';saveData();renderApp();toast(`ورود امن موفق بود؛ نقش ${activeRole().label} فعال شد.`);return;
      } catch(err) {toast(err.message||'اتصال به PocketBase انجام نشد.','error');return;}
    }
    db.pbToken='';db.pbUserId='';db.serverUserName='';db.role=document.getElementById('login-role').value;db.loggedIn=true;db.activePage='dashboard';saveData();renderApp();toast(`حالت نمایشی با نقش ${activeRole().label} فعال شد.`);return;
  }
  if(event.target.id==='customer-form') {event.preventDefault();const f=event.target;const id=`c-${Date.now()}`;db.customers.unshift({id,code:`C-${faNum(1204+db.customers.length)}`,name:f.elements.name.value,phone:f.elements.phone.value,type:f.elements.type.value,group:f.elements.group.value,adjustment:f.elements.group.value==='همکاران ویژه'?-2:f.elements.group.value==='همکاران'?-1:0,balance:0,limit:Number(f.elements.limit.value)||0,city:f.elements.city.value||'—',active:true});saveData();closeModal();renderApp();toast('مشتری جدید ثبت شد.');return;}
  if(event.target.id==='supplier-form') {event.preventDefault();const f=event.target;db.suppliers.unshift({id:`s-${Date.now()}`,code:`S-${String(db.suppliers.length+1).padStart(3,'0')}`,name:f.elements.name.value,phone:f.elements.phone.value,address:f.elements.address.value,notes:f.elements.notes.value,balance:0});saveData();closeModal();renderApp();toast('تأمین‌کننده ثبت شد.');return;}
  if(event.target.id==='product-form') {event.preventDefault();const f=event.target;const baseUnit=f.elements.baseUnit.value;const p={id:`p-${Date.now()}`,code:f.elements.code.value,name:f.elements.name.value,group:f.elements.group.value,baseUnit,stockBase:Number(f.elements.stock.value)||0,minStock:Number(f.elements.minStock.value)||0,baseCost:Number(f.elements.baseCost?.value)||0,baseSell:roundedPrice(applyTomanPercent(Number(f.elements.baseCost?.value)||1000000,22)),warehouse:'انبار مرکزی',color:'purple',units:[{name:baseUnit,factor:1}]};db.products.unshift(p);saveData();closeModal();renderApp();toast('کالا ثبت شد.');return;}
  if(event.target.id==='movement-form') {event.preventDefault();saveMovement(event.target);return;}
  if(event.target.id==='cheque-form') {event.preventDefault();const f=event.target;db.cheques.unshift({id:`ch-${Date.now()}`,number:f.elements.number.value,bank:f.elements.bank.value,amount:Number(f.elements.amount.value),party:f.elements.party.value,type:f.elements.type.value,due:f.elements.due.value,status:'in_hand',holder:'بنفشه'});saveData();closeModal();renderApp();toast('چک جدید ثبت شد.');return;}
  if(event.target.id==='invoice-form') {event.preventDefault();saveInvoice('draft');return;}
  if(event.target.id==='settings-form') {event.preventDefault();const f=event.target;db.settings.pbUrl=f.elements.pbUrl.value.trim().replace(/\/$/,'');db.settings.taxRate=Number(f.elements.taxRate.value)||0;saveData();renderApp();toast('تنظیمات ذخیره شد.');return;}
  if(event.target.id==='payment-form') {event.preventDefault();const f=event.target;const c=customerById(f.elements.customerId.value);const amount=Number(f.elements.amount.value)||0;if(c)c.balance=Math.max(0,c.balance-amount);saveData();closeModal();renderApp();toast('دریافت در گردش حساب ثبت شد.');return;}
  if(event.target.id==='deal-form') {event.preventDefault();const f=event.target;const investor=investorById(f.elements.investorId.value);const customer=customerById(f.elements.customerId.value);const companyPrice=Number(f.elements.companyPrice.value)||0;const customerPrice=Number(f.elements.customerPrice.value)||0;db.deals.unshift({id:`d-${Date.now()}`,investorId:investor.id,investor:investor.name,customer:customer.name,date:f.elements.date.value||TODAY,companyPrice,customerPrice,investorProfit:Math.max(0,customerPrice-companyPrice),companyCost:Number(f.elements.companyCost?.value)||0,status:'open',chequeCount:Number(f.elements.chequeCount.value)||0});saveData();closeModal();renderApp();toast('معامله سرمایه‌گذاری ثبت شد.');return;}
  if(event.target.id==='settlement-form') {event.preventDefault();const f=event.target;const related=db.deals.filter(d=>d.investorId===f.elements.investorId.value&&d.status==='open');if(related.length)related[0].status='settled';saveData();closeModal();renderApp();toast('تسویه ثبت و یک معامله باز به‌روزرسانی شد.');return;}
});
function downloadTemplate(type='products') {
  if(type==='customers') downloadCSV('قالب-مشتریان.csv',[['کد مشتری','نام مشتری','شماره تماس','نشانی','نوع مشتری','گروه قیمت','سقف اعتبار','مانده افتتاحیه'],['C-0001','نمونه مشتری','۰۹۱۲۰۰۰۰۰۰۰','تهران','عمده','همکاران','50000000','0']]);
  else if(type==='suppliers') downloadCSV('قالب-تامین-کنندگان.csv',[['کد تامین‌کننده','نام تامین‌کننده','شماره تماس','نشانی','یادداشت','مانده پرداختنی'],['S-001','تامین‌کننده نمونه','۰۲۱۱۲۳۴۵۶۷۸','تهران','توضیح نمونه','0']]);
  else downloadCSV('قالب-کالاها.csv',[['کد کالا','نام کالا','گروه','واحد پایه','موجودی افتتاحیه','حداقل موجودی','قیمت خرید محرمانه'],['PR-060-WH','پروفیل ۶۰ سفید','پروفیل فریم','شاخه','0','50','']]);
  toast('قالب CSV سازگار با Excel دانلود شد.');
}
function parseCSV(text) {
  const rows=[];let row=[],cell='',quoted=false;const source=String(text).replace(/^\uFEFF/,'');
  for(let i=0;i<source.length;i++) {
    const char=source[i];
    if(char==='"'&&quoted&&source[i+1]==='"'){cell+='"';i++;continue;}
    if(char==='"'){quoted=!quoted;continue;}
    if(char===','&&!quoted){row.push(cell.trim());cell='';continue;}
    if((char==='\n'||char==='\r')&&!quoted){if(char==='\r'&&source[i+1]==='\n')i++;row.push(cell.trim());if(row.some(v=>v!==''))rows.push(row);row=[];cell='';continue;}
    cell+=char;
  }
  row.push(cell.trim());if(row.some(v=>v!==''))rows.push(row);return rows;
}
function parseNumeric(value) { const english=String(value||'').replace(/[۰-۹]/g,d=>String(faDigits.indexOf(d))).replace(/[٬,\s]/g,'');return Number(english)||0; }
document.getElementById('import-file')?.addEventListener('change', async event=>{
  const file=event.target.files?.[0];if(!file)return;
  const type=event.target.dataset.template||'products';
  const rows=parseCSV(await file.text());
  if(rows.length<2){toast('فایل خالی یا نامعتبر است.','error');return;}
  let imported=0;
  for(const row of rows.slice(1)) {
    if(row.length<2||!row[1])continue;
    if(type==='customers') {
      const [code,name,phone,address,customerType='عمده',group='همکاران',limit='0',opening='0']=row;
      if(db.customers.some(c=>c.code===code||c.phone===phone))continue;
      db.customers.push({id:`c-${Date.now()}-${imported}`,code:code||`C-${1200+db.customers.length}`,name,phone,address,type:customerType,group,adjustment:group==='همکاران ویژه'?-2:group==='همکاران'?-1:0,balance:parseNumeric(opening),limit:parseNumeric(limit),city:'—',active:true});
    } else if(type==='suppliers') {
      const [code,name,phone,address,notes='',balance='0']=row;
      if(db.suppliers.some(s=>s.code===code||s.phone===phone))continue;
      db.suppliers.push({id:`s-${Date.now()}-${imported}`,code:code||`S-${String(db.suppliers.length+1).padStart(3,'0')}`,name,phone,address,notes,balance:parseNumeric(balance)});
    } else {
      const [code,name,group,unit='عدد',stock='0',min='0',cost='0']=row;
      if(db.products.some(p=>p.code===code))continue;
      const baseCost=parseNumeric(cost);
      db.products.push({id:`p-${Date.now()}-${imported}`,code,name,group:group||'سایر',baseUnit:unit||'عدد',stockBase:parseNumeric(stock),minStock:parseNumeric(min),baseCost,baseSell:roundedPrice(applyTomanPercent(baseCost,22)),warehouse:'انبار مرکزی',color:'purple',units:[{name:unit||'عدد',factor:1}]});
    }
    imported++;
  }
  saveData();event.target.value='';event.target.dataset.template='products';renderApp();toast(`${faNum(imported)} ردیف با موفقیت وارد شد.`);
});

renderApp();
