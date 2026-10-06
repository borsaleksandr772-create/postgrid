export async function inspectVideo(file){
 if(!file.size)throw Error('Файл пустой. Дождитесь скачивания видео из iCloud и выберите его снова.');
 if(file.size>52428800)throw Error(`Видео весит ${(file.size/1048576).toFixed(1)} МБ. Сейчас можно загрузить до 50 МБ. Экспортируйте уменьшенную копию.`);
 const bytes=new Uint8Array(await file.slice(0,64).arrayBuffer());
 const text=new TextDecoder('ascii').decode(bytes);
 if(text.slice(4,8)!=='ftyp'||text.slice(8,12)==='qt  '||/\.mov$/i.test(file.name)||file.type==='video/quicktime')throw Error('Это видео не в формате MP4. Пока поддерживается MP4 (H.264/AAC) до 50 МБ. MOV с iPhone нужно экспортировать в MP4 — переименование файла не поможет.');
 return 'video/mp4';
}

export function videoDuration(video,url,timeout=45000){
 return new Promise((resolve,reject)=>{
  let timer;
  const finish=(error)=>{clearTimeout(timer);video.removeEventListener('loadedmetadata',loaded);video.removeEventListener('durationchange',loaded);video.removeEventListener('error',failed);error?reject(error):resolve(video.duration);};
  const loaded=()=>{if(Number.isFinite(video.duration)&&video.duration>0)finish();};
  const failed=()=>finish(Error('Телефон не смог прочитать видео. Попробуйте MP4 с кодеком H.264, сохранённый в «Файлы».'));
  video.addEventListener('loadedmetadata',loaded);video.addEventListener('durationchange',loaded);video.addEventListener('error',failed);
  timer=setTimeout(()=>finish(Error('Видео не прочиталось за 45 секунд. Скачайте оригинал из iCloud в «Файлы» и выберите его повторно.')),timeout);
  video.preload='metadata';video.playsInline=true;video.muted=true;video.src=url;video.load();loaded();
 });
}
