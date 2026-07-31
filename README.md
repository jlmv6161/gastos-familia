# Gastos Familia — Mariana y José Luis

Capa pública del tablero de gastos familiares.

**https://jlmv6161.github.io/gastos-familia/**

## Qué hay aquí

Un solo archivo, `index.html`, que contiene el dashboard **cifrado con AES-256**
(clave derivada con PBKDF2-SHA256, 150 000 iteraciones, de `usuario:contraseña`).
Al entrar la clave correcta, el navegador descifra el contenido y lo muestra;
sin ella el archivo es ruido, aunque el repositorio sea público.

No hay servidor ni base de datos: todo el cálculo pasa en el navegador de quien
entra. Las credenciales no viajan a ningún lado.

## Qué NO hay aquí

Los datos en claro (`data.js`, el CSV del Google Sheets), el dashboard sin login
y las credenciales. Todo eso vive solo en la carpeta de trabajo
`Documents\Claude\Gastos Familia Mariana y Jose Luis` y está bloqueado por
`.gitignore`.

## Cómo actualizar

En la carpeta de trabajo, para traer los gastos nuevos del Sheet y regenerar el
`index.html` cifrado:

```powershell
powershell -ExecutionPolicy Bypass -File .\actualizar-datos.ps1
```

Y luego, desde esta carpeta, para subirlo:

```powershell
powershell -ExecutionPolicy Bypass -File .\publicar.ps1
```

`publicar.ps1` copia el `index.html` recién generado, revisa que no se cuele
ningún archivo con datos en claro y hace el commit y el push. Se niega a
publicar si la contraseña sigue siendo la provisional.

GitHub Pages tarda 1–2 minutos en reflejar el cambio.
