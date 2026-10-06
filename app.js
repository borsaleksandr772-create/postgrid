const PLATFORMS = [
  {id:'instagram', name:'Instagram Reels', icon:'◎'},
  {id:'tiktok', name:'TikTok', icon:'♪'},
  {id:'youtube', name:'YouTube Shorts', icon:'▶'},
  {id:'x', name:'X', icon:'𝕏'}
];
const state = {
  tab: localStorage.getItem('pg.tab') || 'calendar',
  month: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
  posts: JSON.parse(localStorage.getItem('pg.posts') || '[]'),
  accounts: JSON.parse(localStorage.getItem('pg.accounts') || '{}'),
  file: null,
  previewURL: null,
  draft: freshDraft()
};
function freshDraft(){
  const d = new Date(Date.now()+60*60*1000); d.setMinutes(0,0,0);
  const local = toLocalInput(d);
  return {name:'', defaultCaption:'', platforms:Object.fromEntries(PLATFORMS.map(p=>[p.id,{enabled:false,when:local,caption:'',title:''}]))};
}
function toLocalInput(d){ const z=n=>String(n).padStart(2,'0'); return `${d.getFullYear()}-${z(d.getMonth()+1)}-${z(d.getDate())}T${z(d.getHours())}:${z(d.getMinutes())}`; }
function save(){ localStorage.setItem('pg.posts',JSON.stringify(state.posts)); localStorage.setItem('pg.accounts',JSON.stringify(state.accounts)); localStorage.setItem('pg.tab',state.tab); }
function fmt(dt){ return new Intl.DateTimeFormat('ru-RU',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}).format(new Date(dt)); }
function monthTitle(d){return new Intl.DateTimeFormat('ru-RU',{month:'long',year:'numeric'}).format(d).replace(/^./,m=>m.toUpperCase())}
function app(){ document.getElementById('app').innerHTML = `<main class="shell"><header class="topbar"><div class="eyebrow">PostGrid</div><h1>${titleForTab()}</h1></header>${view()}</main>${tabs()}`; bind(); }
function titleForTab(){return ({calendar:'Календарь',composer:'Новый пост',queue:'Очередь',accounts:'Аккаунты'})[state.tab]}
function tabs(){ return `<nav class="tabs">${[['calendar','▦','Календарь'],['composer','＋','Пост'],['queue','≡','Очередь'],['accounts','◉','Аккаунты']].map(([id,ic,n])=>`<button class="tab ${state.tab===id?'active':''}" data-tab="${id}"><span class="ico">${ic}</span>${n}</button>`).join('')}</nav>`}
function view(){ if(state.tab==='calendar')return calendarView(); if(state.tab==='composer')return composerView(); if(state.tab==='queue')return queueView(); return accountsView(); }
function calendarView(){
  const m=state.month, y=m.getFullYear(), mon=m.getMonth();
  const start=new Date(y,mon,1); let startOffset=(start.getDay()+6)%7; const first=new Date(y,mon,1-startOffset);
  let cells=''; const today=new Date();
  for(let i=0;i<42;i++){
    const d=new Date(first); d.setDate(first.getDate()+i); const key=`${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
    const items=[]; state.posts.forEach(p=>Object.entries(p.platforms||{}).forEach(([pid,x])=>{if(x.enabled){const dt=new Date(x.when);if(`${dt.getFullYear()}-${dt.getMonth()}-${dt.getDate()}`===key)items.push({pid,time:dt,title:p.name||'Видео'})}}));
    const isToday=d.toDateString()===today.toDateString();
    cells+=`<div class="day ${d.getMonth()!==mon?'out':''} ${isToday?'today':''}"><div class="num">${d.getDate()}</div>${items.slice(0,3).map(it=>`<div class="dot">${PLATFORMS.find(p=>p.id===it.pid)?.icon||''} ${String(it.time.getHours()).padStart(2,'0')}:${String(it.time.getMinutes()).padStart(2,'0')}</div>`).join('')}${items.length>3?`<div class="dot">+${items.length-3}</div>`:''}</div>`;
  }
  return `<section class="card"><div class="calendar-head"><button class="ghost" id="prevMonth">‹</button><h2>${monthTitle(m)}</h2><button class="ghost" id="nextMonth">›</button></div><div class="calendar-grid">${['Пн','Вт','Ср','Чт','Пт','Сб','Вс'].map(x=>`<div class="dow">${x}</div>`).join('')}${cells}</div></section><button class="primary" id="newPost" style="width:100%">＋ Запланировать ролик</button>`;
}
function composerView(){
  const d=state.draft;
  return `<section class="card"><div class="section-title">Видео</div><div class="composer-video"><div class="video-box">${state.previewURL?`<video src="${state.previewURL}" muted playsinline></video>`:'Одно видео<br>для всех сетей'}</div><div style="flex:1"><input type="file" id="videoFile" accept="video/*" /><div class="muted" style="font-size:12px;margin-top:7px">Выбираешь ролик один раз.</div></div></div><label class="small">Название внутри PostGrid</label><input id="postName" value="${esc(d.name)}" placeholder="Например: Иван — Париж"/><label class="small">Общее описание</label><textarea id="defaultCaption" placeholder="Будет подставлено во все выбранные соцсети">${esc(d.defaultCaption)}</textarea></section>
  <section class="card"><div class="section-title">Куда и когда</div><div class="muted" style="font-size:13px">У каждой отмеченной сети — своё время и при желании свой текст.</div>${PLATFORMS.map(p=>platformEditor(p,d.platforms[p.id])).join('')}<div class="quick"><button id="sameTime">Одно время для всех</button><button id="clearPlatforms" class="ghost">Снять все</button></div></section>
  <button class="primary" id="schedule" style="width:100%;padding:15px">Запланировать выбранные</button>`;
}
function platformEditor(p,x){return `<div class="platform ${x.enabled?'enabled':''}" data-platform="${p.id}"><div class="platform-head"><div style="font-size:22px">${p.icon}</div><div class="platform-name">${p.name}</div><button class="switch ${x.enabled?'on':''}" data-toggle="${p.id}" aria-label="toggle"><i></i></button></div><div class="platform-body"><label class="small">Дата и время</label><input type="datetime-local" data-when="${p.id}" value="${x.when}">${p.id==='youtube'?`<label class="small">Заголовок YouTube</label><input data-title="${p.id}" value="${esc(x.title)}" placeholder="Название Short">`:''}<label class="small">Описание для этой сети</label><textarea data-caption="${p.id}" placeholder="Оставь пустым — возьмём общее">${esc(x.caption)}</textarea></div></div>`}
function queueView(){
  if(!state.posts.length)return `<div class="empty">Пока ничего не запланировано.<br><br><button class="primary" id="newPost">Создать первый пост</button></div>`;
  const posts=[...state.posts].sort((a,b)=>earliest(a)-earliest(b));
  return posts.map(p=>`<section class="card"><div class="queue-item"><div class="thumb">🎬</div><div class="queue-main"><div class="queue-title">${esc(p.name||'Без названия')}</div><div class="muted" style="font-size:12px;margin-top:4px">${esc(p.fileName||'Видео')}</div></div><button class="danger" data-delete="${p.id}">Удалить</button></div><div style="margin-top:10px">${Object.entries(p.platforms).filter(([,x])=>x.enabled).map(([pid,x])=>`<div class="dest"><span>${PLATFORMS.find(z=>z.id===pid)?.icon} ${PLATFORMS.find(z=>z.id===pid)?.name}</span><span><span class="badge">${fmt(x.when)}</span></span></div>`).join('')}</div></section>`).join('');
}
function earliest(p){const arr=Object.values(p.platforms||{}).filter(x=>x.enabled).map(x=>new Date(x.when).getTime());return Math.min(...arr)}
function accountsView(){return `<div class="notice">Как в приложении для английского: эту версию можно установить с Safari на экран «Домой». OAuth для реальной публикации подключим следующим этапом — пароли PostGrid видеть не будет.</div><div style="height:12px"></div>${PLATFORMS.map(p=>{const on=!!state.accounts[p.id];return `<section class="card account"><div class="logo">${p.icon}</div><div class="grow"><div style="font-weight:850">${p.name}</div><div class="status">${on?'Подключение помечено для теста':'Не подключено'}</div></div><button data-account="${p.id}" class="${on?'ghost':'primary'}">${on?'Отключить':'Подключить'}</button></section>`}).join('')}<section class="card"><div class="section-title">Режим MVP</div><div class="muted" style="font-size:13px;line-height:1.5">Сейчас расписание хранится на самом iPhone. После подключения backend + OAuth публикации будут уходить с сервера даже когда PostGrid закрыт.</div></section>`}
function bind(){
  document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{state.tab=b.dataset.tab;save();app()});
  by('prevMonth',()=>{state.month=new Date(state.month.getFullYear(),state.month.getMonth()-1,1);app()}); by('nextMonth',()=>{state.month=new Date(state.month.getFullYear(),state.month.getMonth()+1,1);app()}); by('newPost',()=>{state.tab='composer';save();app()});
  const f=document.getElementById('videoFile'); if(f)f.onchange=e=>{state.file=e.target.files[0]||null;if(state.previewURL)URL.revokeObjectURL(state.previewURL);state.previewURL=state.file?URL.createObjectURL(state.file):null;app()};
  const name=document.getElementById('postName'); if(name)name.oninput=e=>state.draft.name=e.target.value; const dc=document.getElementById('defaultCaption'); if(dc)dc.oninput=e=>state.draft.defaultCaption=e.target.value;
  document.querySelectorAll('[data-toggle]').forEach(b=>b.onclick=()=>{const id=b.dataset.toggle;state.draft.platforms[id].enabled=!state.draft.platforms[id].enabled;app()});
  document.querySelectorAll('[data-when]').forEach(i=>i.oninput=e=>state.draft.platforms[e.target.dataset.when].when=e.target.value);
  document.querySelectorAll('[data-caption]').forEach(i=>i.oninput=e=>state.draft.platforms[e.target.dataset.caption].caption=e.target.value);
  document.querySelectorAll('[data-title]').forEach(i=>i.oninput=e=>state.draft.platforms[e.target.dataset.title].title=e.target.value);
  by('sameTime',()=>{const enabled=Object.values(state.draft.platforms).filter(x=>x.enabled);const base=enabled[0]?.when||toLocalInput(new Date());Object.values(state.draft.platforms).forEach(x=>{if(x.enabled)x.when=base});app()}); by('clearPlatforms',()=>{Object.values(state.draft.platforms).forEach(x=>x.enabled=false);app()});
  by('schedule',()=>{if(!Object.values(state.draft.platforms).some(x=>x.enabled))return toast('Отметь хотя бы одну соцсеть'); if(!state.file)return toast('Сначала выбери видео'); state.posts.push({id:crypto.randomUUID(),name:state.draft.name||state.file.name,fileName:state.file.name,defaultCaption:state.draft.defaultCaption,platforms:JSON.parse(JSON.stringify(state.draft.platforms)),createdAt:new Date().toISOString()}); state.draft=freshDraft();state.file=null;if(state.previewURL)URL.revokeObjectURL(state.previewURL);state.previewURL=null;state.tab='queue';save();toast('Добавлено в расписание');app()});
  document.querySelectorAll('[data-delete]').forEach(b=>b.onclick=()=>{state.posts=state.posts.filter(p=>p.id!==b.dataset.delete);save();app()});
  document.querySelectorAll('[data-account]').forEach(b=>b.onclick=()=>{const id=b.dataset.account;state.accounts[id]=!state.accounts[id];save();app()});
}
function by(id,fn){const el=document.getElementById(id);if(el)el.onclick=fn}
function toast(msg){const e=document.createElement('div');e.className='toast';e.textContent=msg;document.body.appendChild(e);setTimeout(()=>e.remove(),1800)}
function esc(s=''){return String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]))}
if('serviceWorker' in navigator)window.addEventListener('load',()=>navigator.serviceWorker.register('./service-worker.js'));
app();
