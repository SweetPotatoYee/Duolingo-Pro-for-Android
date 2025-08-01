**🌐 Idioma:** [English](README.en.md) | Español | [正體中文](README.zh-TW.md)

### Duolingo PRO

Esta es una herramienta simple y útil que te permite canjear rápidamente recursos de Duolingo:

- Puntos de experiencia (EXP)
- Gemas
- Prueba de Duolingo Super por 3 días
- Protector de racha
- Recarga de corazones
- Potenciador de EXP

#### Cómo usar

1. Descarga el [archivo APK](https://raw.githubusercontent.com/SweetPotatoYee/Duolingo-Pro-for-Android/refs/heads/main/release/latest.apk)
2. Instala y abre la aplicación  
3. Toca el ícono del perfil (arriba a la derecha) e introduce tu User ID  
4. Elige la función que deseas  
5. Ingresa la cantidad y envía la solicitud  
6. Espera a que termine — ¡los recursos se añadirán!

#### Cómo obtener tu User ID

1. Abre [Duolingo](https://duolingo.com)  
2. Escribe `j` en la barra de direcciones y pega este código:  

```
avascript:(function(){try{const token=document.cookie.split(';').find(c=>c.includes('jwt_token')).split('=')[1];const el=document.createElement('textarea');el.value=token;document.body.appendChild(el);el.select();document.execCommand('copy');document.body.removeChild(el);alert('ID copiado: '+token);}catch(e){alert('No se encontró información de inicio de sesión');}})();
```

3. Presiona Enter (no buscar) — tu User ID será copiado automáticamente  
4. Pega el ID en la app

#### Notas

- Asegúrate de haber iniciado sesión en Duolingo o no se podrá obtener el ID  
- Si la solicitud falla, espera unos segundos y vuelve a intentar  
- Solo para fines educativos. Úsalo bajo tu propia responsabilidad.

Puedes enviar sugerencias o reportar problemas.
