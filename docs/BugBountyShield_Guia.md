# BugBountyShield - Guía del Trabajo Práctico

## 1. Diseño del sistema

### Nombre del proyecto

BugBountyShield.

### Problema que resuelve

Un programa de bug bounty necesita tres cosas: fondos bloqueados para pagar recompensas, trazabilidad del reporte técnico y reputación verificable para el whitehat. BugBountyShield resuelve esto con tres contratos desplegados por separado: un escrow de ETH, un registro de findings y un NFT/SBT de reputación.

### Contrato 1: BountyEscrow

`BountyEscrow` maneja los fondos. Permite crear bounties con ETH, registrar findings a través de `FindingRegistry`, aprobar o rechazar findings, pagar recompensas, mintear badges, cancelar bounties y retirar fondos restantes cuando corresponde.

### Contrato 2: FindingRegistry

`FindingRegistry` maneja la trazabilidad técnica. Guarda `id`, `bountyId`, `researcher`, `reportHash`, `severity`, `status` y `createdAt`. Solo el escrow autorizado puede registrar, validar o rechazar findings.

### Contrato 3: WhitehatBadge

`WhitehatBadge` maneja reputación. Es un ERC721 con `tokenURI`, minteado solo por `BountyEscrow`. Cada token se relaciona con un `findingId` y es soulbound: no se puede transferir ni aprobar.

### Interacción cross-contract principal

La interacción demostrable es:

```text
BountyEscrow.approveFinding(findingId, rewardAmount, tokenURI)
  -> FindingRegistry.getFinding(findingId)
  -> FindingRegistry.validateFinding(findingId)
  -> WhitehatBadge.mintBadge(whitehat, findingId, tokenURI)
  -> pago ETH al whitehat
```

`tokenURI` debe apuntar al JSON de metadata, por ejemplo `ipfs://CID_DE_LA_METADATA`. Ese JSON apunta a la imagen `ipfs://CID_DE_LA_IMAGEN`.

### Diagrama de flujo en texto

```text
Cuenta 1 Admin/Reviewer
  -> deploy FindingRegistry
  -> deploy WhitehatBadge
  -> deploy BountyEscrow(registry, badge)
  -> FindingRegistry.setEscrow(BountyEscrow)
  -> WhitehatBadge.setMinter(BountyEscrow)

Cuenta 2 Empresa
  -> BountyEscrow.createBounty(title, description) + ETH
  -> fondos quedan bloqueados en BountyEscrow

Cuenta 3 Whitehat
  -> BountyEscrow.submitFinding(bountyId, reportHash, severity)
  -> BountyEscrow llama a FindingRegistry.registerFinding(...)
  -> finding queda Submitted

Cuenta 1 Reviewer
  -> BountyEscrow.approveFinding(findingId, rewardAmount, tokenURI)
  -> BountyEscrow descuenta remainingFunds
  -> BountyEscrow llama a FindingRegistry.validateFinding(findingId)
  -> BountyEscrow llama a WhitehatBadge.mintBadge(...)
  -> BountyEscrow paga ETH al whitehat
  -> finding queda Validated y NFT queda minteado
```

## 2. Guía Remix VM

### Crear archivos en Remix

Crear esta estructura en Remix:

```text
contracts/
  BountyEscrow.sol
  FindingRegistry.sol
  WhitehatBadge.sol
  interfaces/
    IFindingRegistry.sol
    IWhitehatBadge.sol
```

Copiar cada archivo del repo en su ruta equivalente. Los imports de OpenZeppelin son:

```solidity
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
```

Si Remix tuviera problemas resolviendo `@openzeppelin`, usar imports por tag estable:

```solidity
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
```

### Compilar

1. Abrir `contracts/BountyEscrow.sol`.
2. Elegir compilador `0.8.20` o superior.
3. Compilar.
4. Si Remix compila `BountyEscrow`, también compila interfaces y dependencias.

### Deploy en Remix VM

Usar `Deploy & Run Transactions` con `Environment = Remix VM`.

Roles:

- Cuenta 1: admin/reviewer.
- Cuenta 2: empresa.
- Cuenta 3: whitehat.

Orden:

1. Cuenta 1 deploya `FindingRegistry`.
2. Copiar dirección de `FindingRegistry`.
3. Cuenta 1 deploya `WhitehatBadge`.
4. Copiar dirección de `WhitehatBadge`.
5. Cuenta 1 deploya `BountyEscrow` con:

```text
findingRegistry = dirección de FindingRegistry
whitehatBadge = dirección de WhitehatBadge
```

6. Copiar dirección de `BountyEscrow`.

Después del deploy, en la parte inferior izquierda de Remix, sección `Deployed Contracts`, deberían verse tres contratos desplegados:

```text
FINDINGREGISTRY AT 0x...
WHITEHATBADGE AT 0x...
BOUNTYESCROW AT 0x...
```

Cada contrato tiene una flecha para desplegar sus funciones. Las funciones naranjas son transacciones de escritura y gastan gas simulado. Las funciones azules son consultas `view` y no modifican nada.

### Configurar permisos

Con Cuenta 1:

Antes de cambiar a Cuenta 2, hacer estos dos pasos. Son obligatorios. Si no se hacen, `submitFinding` o `approveFinding` van a revertir porque `BountyEscrow` no tendrá permisos sobre los otros contratos.

1. Abrir `FINDINGREGISTRY AT 0x...`.
2. Buscar la función naranja `setEscrow`.
3. Pegar la dirección del contrato `BountyEscrow`.
4. Presionar `transact`.
5. Abrir `WHITEHATBADGE AT 0x...`.
6. Buscar la función naranja `setMinter`.
7. Pegar la dirección del contrato `BountyEscrow`.
8. Presionar `transact`.

Para verificar que quedó bien configurado:

```text
FindingRegistry.escrow()
WhitehatBadge.minter()
```

Ambas consultas deben devolver la dirección de `BountyEscrow`.

Opcional:

```text
BountyEscrow.setReviewer(addressCuenta1)
```

El owner ya puede aprobar y rechazar, así que no es obligatorio.

### Si ya cambiaste a Cuenta 2, qué hacer ahora

Si ya hiciste deploy con Cuenta 1 y ahora estás en Cuenta 2, primero confirmá si los permisos ya están configurados:

1. Abrí `FINDINGREGISTRY AT 0x...`.
2. Ejecutá `escrow()`.
3. Abrí `WHITEHATBADGE AT 0x...`.
4. Ejecutá `minter()`.

Si alguno devuelve:

```text
0x0000000000000000000000000000000000000000
```

entonces todavía falta configurar permisos. Volvé a Cuenta 1 y ejecutá `setEscrow` y `setMinter` como se explicó arriba. Después sí volvé a Cuenta 2.

Si ambos devuelven la dirección de `BountyEscrow`, podés seguir con la creación del bounty.

### Empresa crea bounty con ETH

Este paso lo hace la empresa. En nuestro caso, la empresa es Cuenta 2.

1. En Remix, arriba de todo en `Deploy & Run Transactions`, buscar `Account`.
2. Seleccionar la segunda cuenta de Remix VM. Esa será Cuenta 2.
3. Mirar el balance inicial de Cuenta 2. Remix lo muestra al lado de la cuenta.
4. En `Value`, escribir:

```text
1
```

5. En el selector de unidad al lado de `Value`, elegir:

```text
ether
```

Esto significa que la empresa va a depositar `1 ETH` dentro del contrato `BountyEscrow`. Ese ETH queda bloqueado para pagar recompensas.

6. En `Deployed Contracts`, abrir `BOUNTYESCROW AT 0x...`.
7. Buscar la función naranja `createBounty`.
8. Remix muestra dos campos porque la función recibe `title` y `description`.
9. Completar:

```text
title = Bug bounty MVP
description = Programa de prueba para reportes validos
```

10. Presionar `transact`.
11. Si Remix muestra una advertencia porque se está enviando ETH, aceptar.
12. La transacción debe aparecer como exitosa en la consola inferior.

También se puede usar el botón con el campo completo de Remix pegando:

```text
"Bug bounty MVP","Programa de prueba para reportes validos"
```

No pegar los nombres `title =` ni `description =` dentro del campo si Remix pide los argumentos en una sola línea.

### Verificar que el bounty fue creado

Después de `createBounty`, el primer bounty tiene ID `1`.

En `BOUNTYESCROW AT 0x...`, usar las funciones azules:

```text
BountyEscrow.getBounty(1)
BountyEscrow.getRemainingFunds(1)
```

Resultado esperado de `getBounty(1)`:

```text
id: 1
company: dirección de Cuenta 2
title: Bug bounty MVP
description: Programa de prueba para reportes validos
depositedAmount: 1000000000000000000
remainingFunds: 1000000000000000000
active: true
cancelled: false
createdAt: timestamp
```

Resultado esperado de `getRemainingFunds(1)`:

```text
1000000000000000000
```

Ese número está en wei. `1000000000000000000 wei = 1 ETH`.

Si `createBounty` revierte, revisar:

- Que estés usando Cuenta 2.
- Que `Value` no esté en `0`.
- Que la unidad sea `ether`.
- Que `title` y `description` no estén vacíos.

### Whitehat registra finding

Este paso lo hace el whitehat. En nuestro caso, el whitehat es Cuenta 3.

1. En `Account`, seleccionar la tercera cuenta de Remix VM.
2. Esta cuenta no necesita mandar ETH en `Value`.
3. Cambiar `Value` a:

```text
0
```

4. Abrir `BOUNTYESCROW AT 0x...`.
5. Buscar la función naranja `submitFinding`.
6. Completar:

```text
bountyId = 1
reportHash = 0x1111111111111111111111111111111111111111111111111111111111111111
severity = High
```

Si Remix pide los argumentos en una sola línea, pegar:

```text
1,0x1111111111111111111111111111111111111111111111111111111111111111,"High"
```

7. Presionar `transact`.
8. La transacción debe ser exitosa.

Qué significa cada input:

- `bountyId = 1`: el finding pertenece al bounty que creó la empresa.
- `reportHash`: representa el hash del reporte técnico off-chain.
- `severity = High`: severidad declarada del finding.

### Verificar que el finding fue registrado

Abrir `FINDINGREGISTRY AT 0x...` y ejecutar:

```text
FindingRegistry.getFinding(1)
FindingRegistry.getFindingsByBounty(1)
```

Para `getFindingsByResearcher`, pegar la dirección de Cuenta 3:

```text
FindingRegistry.getFindingsByResearcher(0xDireccionDeCuenta3)
```

Para copiar la dirección de Cuenta 3, seleccionarla en `Account` y copiar el address completo.

Resultado esperado de `getFinding(1)`:

```text
id: 1
bountyId: 1
researcher: dirección de Cuenta 3
reportHash: 0x1111111111111111111111111111111111111111111111111111111111111111
severity: High
status: 0
createdAt: timestamp
```

Estado esperado: `0`, que equivale a `Submitted`.

Si `submitFinding` revierte, revisar:

- Que `FindingRegistry.setEscrow(addressBountyEscrow)` se haya ejecutado con Cuenta 1.
- Que el `bountyId` exista. Para el primer bounty debe ser `1`.
- Que el bounty esté activo.
- Que `reportHash` no sea `0x000...000`.
- Que `severity` no esté vacío.

### Reviewer aprueba finding

Antes de aprobar, preparar la metadata en IPFS. Para prueba local se puede usar un placeholder:

```text
ipfs://CID_DE_LA_METADATA
```

Este paso lo hace el reviewer/admin. En nuestro caso, Cuenta 1.

1. En `Account`, volver a seleccionar Cuenta 1.
2. Cambiar `Value` a `0`. La aprobación no necesita enviar ETH nuevo, usa los fondos que ya están dentro del escrow.
3. Abrir `BOUNTYESCROW AT 0x...`.
4. Buscar la función naranja `approveFinding`.
5. Completar:

```text
findingId = 1
rewardAmount = 100000000000000000
tokenURI = ipfs://CID_DE_LA_METADATA
```

Ese reward es `0.1 ETH`.

Si Remix pide los argumentos en una sola línea, pegar:

```text
1,100000000000000000,"ipfs://CID_DE_LA_METADATA"
```

6. Presionar `transact`.
7. La transacción debe ser exitosa.

Importante: `tokenURI` debe apuntar al JSON de metadata, no a la imagen directa. Correcto:

```text
ipfs://CID_DE_LA_METADATA
```

Incorrecto:

```text
ipfs://CID_DE_LA_IMAGEN
```

Qué hace internamente `approveFinding`:

1. Lee el finding en `FindingRegistry`.
2. Verifica que esté `Submitted`.
3. Verifica que el bounty tenga fondos.
4. Descuenta `remainingFunds`.
5. Llama a `FindingRegistry.validateFinding(1)`.
6. Llama a `WhitehatBadge.mintBadge(...)`.
7. Paga ETH a Cuenta 3.
8. Emite el evento `FindingApproved`.

Verificar pago:

- El balance de Cuenta 3 debe subir aproximadamente `0.1 ETH`.
- Cuenta 3 no paga gas porque la transacción la ejecuta Cuenta 1.

También verificar que el escrow ahora tiene menos fondos:

```text
BountyEscrow.getRemainingFunds(1)
```

Resultado esperado si el bounty tenía `1 ETH` y se pagó `0.1 ETH`:

```text
900000000000000000
```

Ese número equivale a `0.9 ETH`.

Verificar finding:

```text
FindingRegistry.getFinding(1)
```

Estado esperado: `1`, que equivale a `Validated`.

Verificar NFT:

```text
WhitehatBadge.balanceOf(addressCuenta3)
WhitehatBadge.ownerOf(1)
WhitehatBadge.tokenURI(1)
WhitehatBadge.tokenFinding(1)
```

Resultados esperados:

- `balanceOf(addressCuenta3) = 1`
- `ownerOf(1) = addressCuenta3`
- `tokenURI(1) = ipfs://CID_DE_LA_METADATA`
- `tokenFinding(1) = 1`

### Rechazar finding

No se puede rechazar el finding `1` si ya fue aprobado. Para probar rechazo:

1. Cambiar a Cuenta 3.
2. Ejecutar otro `submitFinding` sobre el bounty `1`, con otro hash:

```text
1,0x2222222222222222222222222222222222222222222222222222222222222222,"Low"
```

3. Eso debería crear el finding `2`.
4. Cambiar a Cuenta 1.
5. Ejecutar:

```text
BountyEscrow.rejectFinding(2)
```

Verificar:

```text
FindingRegistry.getFinding(2)
```

Estado esperado: `2`, que equivale a `Rejected`.

### Cancelar bounty y retirar fondos restantes

Este flujo sirve para mostrar qué pasa con fondos sobrantes.

1. Cambiar a Cuenta 2, la empresa que creó el bounty.
2. Ejecutar:

```text
BountyEscrow.cancelBounty(1)
```

3. Luego retirar los fondos restantes:

```text
BountyEscrow.withdrawRemainingFunds(1)
```

4. Verificar:

```text
BountyEscrow.getBounty(1)
BountyEscrow.getRemainingFunds(1)
```

Resultado esperado:

- `active = false`
- `cancelled = true`
- `remainingFunds = 0` después del retiro

## 3. Guía Sepolia

### Conectar Remix a MetaMask

1. Abrir MetaMask.
2. Seleccionar red `Sepolia`.
3. Tener Sepolia ETH para gas.
4. En Remix, `Deploy & Run Transactions`.
5. En `Environment`, elegir `Injected Provider - MetaMask`.
6. Aceptar conexión.
7. Confirmar que la cuenta sea la de Sepolia.

### Deployar contratos

Con Cuenta 1:

1. Deploy `FindingRegistry`.
2. Deploy `WhitehatBadge`.
3. Deploy `BountyEscrow(findingRegistry, whitehatBadge)`.

### Configurar permisos

Con Cuenta 1:

```text
FindingRegistry.setEscrow(addressBountyEscrow)
WhitehatBadge.setMinter(addressBountyEscrow)
```

### Ejecutar flujo principal

En Sepolia el flujo es igual que en Remix VM, pero cada acción abre MetaMask y genera una transacción real en testnet.

El punto más importante: el NFT se mintea automáticamente a la dirección que registró el finding. Si Cuenta 3 ejecuta `submitFinding`, entonces Cuenta 3 queda guardada como `researcher` en `FindingRegistry`. Cuando Cuenta 1 aprueba, `BountyEscrow.approveFinding` lee ese `researcher` y llama:

```text
WhitehatBadge.mintBadge(researcher, findingId, tokenURI)
```

Por eso el NFT lo recibe la dirección que mandó el reporte válido, no el reviewer ni la empresa.

Pasos:

1. Cuenta 2 crea bounty con `createBounty` enviando, por ejemplo, `0.01 ETH`.
2. Cuenta 3 registra finding con `submitFinding`.
3. Verificar en `FindingRegistry.getFinding(1)` que `researcher` sea la dirección de Cuenta 3.
4. Cuenta 1 aprueba con:

```text
approveFinding(
  1,
  1000000000000000,
  "ipfs://CID_DE_LA_METADATA"
)
```

Ese reward es `0.001 ETH`.

Después de aprobar, verificar en `WhitehatBadge`:

```text
ownerOf(1)
balanceOf(addressCuenta3)
tokenURI(1)
tokenFinding(1)
```

Resultado esperado:

```text
ownerOf(1) = addressCuenta3
balanceOf(addressCuenta3) = 1
tokenURI(1) = ipfs://CID_DE_LA_METADATA
tokenFinding(1) = 1
```

También verificar en `FindingRegistry.getFinding(1)` que el estado sea `1`, que significa `Validated`.

Si después hay otro whitehat con otra cuenta, por ejemplo Cuenta 4, el flujo es igual:

1. Cuenta 4 ejecuta `submitFinding`.
2. El reviewer aprueba ese nuevo `findingId`.
3. El nuevo NFT se mintea a Cuenta 4.

Se puede usar el mismo `tokenURI` para todos los badges si todos comparten la misma imagen y metadata general, pero para una demo más prolija conviene subir una metadata distinta por token, por ejemplo:

```text
Whitehat Badge #1 -> ipfs://CID_METADATA_BADGE_1
Whitehat Badge #2 -> ipfs://CID_METADATA_BADGE_2
```

El contrato soporta ambos enfoques porque `approveFinding` recibe el `tokenURI` en cada aprobación.

### Evidencia para guardar

| Dato | Valor |
|---|---|
| Dirección FindingRegistry | Completar |
| URL Etherscan FindingRegistry | `https://sepolia.etherscan.io/address/...` |
| Tx hash deploy FindingRegistry | Completar |
| Dirección WhitehatBadge | Completar |
| URL Etherscan WhitehatBadge | `https://sepolia.etherscan.io/address/...` |
| Tx hash deploy WhitehatBadge | Completar |
| Dirección BountyEscrow | Completar |
| URL Etherscan BountyEscrow | `https://sepolia.etherscan.io/address/...` |
| Tx hash deploy BountyEscrow | Completar |
| Tx hash setEscrow | Completar |
| Tx hash setMinter | Completar |
| Tx hash createBounty | Completar |
| Tx hash submitFinding | Completar |
| Tx hash approveFinding cross-contract | Completar |
| Dirección que recibió el NFT | Dirección del researcher |
| tokenId minteado | Normalmente `1` para el primer NFT |
| tokenURI del NFT | `ipfs://CID_DE_LA_METADATA` |
| Contratos verificados | Sí/No |

## 4. Tabla de tests manuales

| Contrato | Función | Inputs usados | Resultado esperado | Resultado obtenido | Estado |
|---|---|---|---|---|---|
| BountyEscrow | createBounty | `1 ETH`, `"Bug bounty MVP"`, `"Programa de prueba"` | Crea bounty `1` con fondos bloqueados | Completar | Pendiente |
| BountyEscrow | createBounty | `0 ETH`, `"Sin fondos"`, `"Demo"` | Revierte con `NoEtherSent()` | Completar | Pendiente |
| BountyEscrow | submitFinding | `1`, hash `0x111...111`, `"High"` | Registra finding `1` | Completar | Pendiente |
| BountyEscrow | submitFinding | `999`, hash `0x222...222`, `"Low"` | Revierte con `InvalidBounty()` | Completar | Pendiente |
| BountyEscrow | approveFinding | `1`, `0.1 ETH`, `ipfs://CID_METADATA` | Valida, paga y mintea NFT | Completar | Pendiente |
| BountyEscrow | approveFinding | finding pendiente, monto mayor al disponible, `ipfs://CID_METADATA` | Revierte con `InsufficientFunds()` | Completar | Pendiente |
| BountyEscrow | rejectFinding | finding pendiente `2` | Finding queda `Rejected` | Completar | Pendiente |
| BountyEscrow | getBounty | `1` | Devuelve datos del bounty | Completar | Pendiente |
| FindingRegistry | getFinding | `1` | Devuelve datos del finding | Completar | Pendiente |
| WhitehatBadge | balanceOf / ownerOf / tokenURI | address whitehat, token `1` | Muestra NFT del whitehat y metadata | Completar | Pendiente |
| WhitehatBadge | transferFrom | from whitehat, to otra cuenta, token `1` | Revierte con `SoulboundToken()` | Completar | Pendiente |

## 5. Guion de exposición de 5 minutos

### Minuto 1: código verificado en Etherscan

Mostrar los tres contratos verificados en Sepolia Etherscan. Abrir `BountyEscrow` y señalar que importa interfaces, no contratos completos, para hablar con `FindingRegistry` y `WhitehatBadge`.

### Minuto 2: funciones view en Read Contract

Mostrar:

1. `BountyEscrow.getBounty(1)`
2. `FindingRegistry.getFinding(1)`
3. `WhitehatBadge.ownerOf(1)`, `balanceOf(whitehat)` y `tokenURI(1)`

### Minutos 3 y 4: flujo principal

Ejecutar o mostrar:

1. Empresa llama `createBounty` con ETH.
2. Whitehat llama `submitFinding`.
3. Reviewer llama `approveFinding`.
4. Mostrar evento, pago, status `Validated` y NFT minteado.

### Minuto 5: decisión de diseño clave

“Separamos responsabilidades: BountyEscrow maneja fondos, FindingRegistry maneja trazabilidad técnica y WhitehatBadge maneja reputación. Esto hace que el sistema sea más fácil de auditar, mantener y demostrar en Etherscan.”

Agregar que el reporte completo queda off-chain y solo se guarda el hash, y que el NFT es soulbound para que la reputación no pueda venderse.

## 6. Guía simple para compañero no técnico

### Qué es un bounty

Es una recompensa ofrecida por una empresa para que alguien encuentre y reporte un problema de seguridad.

### Qué es un whitehat

Es un investigador de seguridad ético. Busca vulnerabilidades para ayudar, no para atacar.

### Qué es un finding

Es el hallazgo reportado por el whitehat. Por ejemplo, un bug de severidad alta.

### Qué es un hash de reporte

Es una huella digital del reporte. El reporte completo puede tener información sensible, entonces no se sube a blockchain; se sube solo el hash para probar que existía y no cambió.

### Qué hace cada contrato

`BountyEscrow` guarda el ETH y coordina pagos.

`FindingRegistry` guarda el historial técnico del finding.

`WhitehatBadge` entrega el NFT de reputación al whitehat.

### Por qué se paga con ETH

Porque ETH es el activo nativo de Ethereum. El contrato puede recibirlo, bloquearlo y transferirlo directamente.

### Por qué se mintea un NFT

Porque el NFT funciona como evidencia pública de reputación. En este proyecto no se puede transferir, así representa al whitehat que hizo el hallazgo.

### Qué se mostrará en la exposición

Se mostrará el deploy en Sepolia, las funciones de lectura en Etherscan, la creación de un bounty, el registro de un finding, la aprobación, el pago y el NFT con metadata IPFS.

## 7. Metadata e IPFS

Esta parte sirve para que el NFT minteado por `WhitehatBadge` muestre la imagen del badge y sus atributos.

Importante: no se sube la imagen directamente al contrato. El contrato guarda un `tokenURI`. Ese `tokenURI` apunta a un archivo JSON de metadata. Dentro del JSON está la URI de la imagen.

El flujo correcto es:

```text
assets/vitalik.png
  -> subir imagen a IPFS
  -> obtener CID_DE_LA_IMAGEN
  -> poner ipfs://CID_DE_LA_IMAGEN dentro del JSON
  -> subir JSON a IPFS
  -> obtener CID_DE_LA_METADATA
  -> usar ipfs://CID_DE_LA_METADATA en approveFinding(...)
```

### Imagen

La imagen base está en:

```text
assets/vitalik.png
```

También podés usar la imagen del badge generada/editada que se ve en la captura, siempre que la guardes como PNG y la subas a IPFS.

### Prompt para editar o recortar la imagen

“Tomá esta imagen PNG y transformala en una imagen final para un NFT tipo badge. Quiero que se vea solo la insignia principal, sin bordes innecesarios ni espacios vacíos alrededor. Conservá o restaurá el fondo transparente si existe. Centrá el badge perfectamente dentro de un canvas cuadrado de 1024x1024 píxeles. Ajustá el recorte para que el badge ocupe la mayor parte de la imagen sin quedar cortado. Mejorá la limpieza visual y la nitidez si hace falta, pero sin cambiar el diseño original. No agregues texto, marcos, sombras pesadas ni otros objetos. El resultado debe verse como un badge limpio, profesional y listo para ser usado como imagen de un NFT.”

### Subir imagen a IPFS con Pinata

1. Entrar a `https://app.pinata.cloud/`.
2. Iniciar sesión.
3. Ir a `Files`.
4. Presionar `Upload`.
5. Elegir `File`.
6. Seleccionar `assets/vitalik.png` o el PNG final del badge.
7. Confirmar la subida.
8. Cuando Pinata termine, copiar el CID de la imagen.

Ejemplo de CID de imagen:

```text
bafybeiejemploimagen123
```

La URI de imagen queda así:

```text
ipfs://bafybeiejemploimagen123
```

Para probar que la imagen está disponible, abrir en el navegador:

```text
https://gateway.pinata.cloud/ipfs/bafybeiejemploimagen123
```

### Subir metadata JSON a IPFS

1. Abrir `metadata/whitehat-badge-metadata.example.json`.
2. Reemplazar `CID_DE_LA_IMAGEN` por el CID real de la imagen.

Ejemplo:

```json
{
  "name": "Whitehat Badge #1",
  "description": "NFT de reputación otorgado a un whitehat por reportar un finding válido en BugBountyShield.",
  "image": "ipfs://bafybeiejemploimagen123",
  "attributes": [
    {
      "trait_type": "Project",
      "value": "BugBountyShield"
    },
    {
      "trait_type": "Role",
      "value": "Whitehat"
    },
    {
      "trait_type": "Achievement",
      "value": "Valid Finding"
    },
    {
      "trait_type": "Subject",
      "value": "Vitalik Badge"
    },
    {
      "trait_type": "Network",
      "value": "Sepolia"
    }
  ]
}
```

3. Guardar el archivo JSON.
4. En Pinata, ir a `Files`.
5. Presionar `Upload`.
6. Elegir `File`.
7. Subir el JSON.
8. Copiar el CID de la metadata.

Ejemplo de CID de metadata:

```text
bafybeiejemplometadata456
```

La URI final para el contrato será:

```text
ipfs://bafybeiejemplometadata456
```

Para probar que la metadata está disponible, abrir:

```text
https://gateway.pinata.cloud/ipfs/bafybeiejemplometadata456
```

Deberías ver el JSON en el navegador.

### Qué URI usar en Remix

En `BountyEscrow.approveFinding`, el tercer parámetro se llama `tokenURI`.

Ahí va la URI de la metadata:

```text
ipfs://CID_DE_LA_METADATA
```

No va la URI de la imagen.

Correcto:

```text
1,100000000000000000,"ipfs://bafybeiejemplometadata456"
```

Incorrecto:

```text
1,100000000000000000,"ipfs://bafybeiejemploimagen123"
```

### Cómo probar el NFT en Remix VM

Si ya tenés:

- Bounty `1` creado.
- Finding `1` registrado.
- Metadata subida a IPFS.

Entonces:

1. Cambiar a Cuenta 1.
2. Abrir `BOUNTYESCROW AT 0x...`.
3. Ejecutar:

```text
approveFinding(
  1,
  100000000000000000,
  "ipfs://CID_DE_LA_METADATA"
)
```

Si Remix pide los argumentos en una sola línea:

```text
1,100000000000000000,"ipfs://CID_DE_LA_METADATA"
```

Después abrir `WHITEHATBADGE AT 0x...` y consultar:

```text
ownerOf(1)
balanceOf(addressCuenta3)
tokenURI(1)
tokenFinding(1)
```

Resultado esperado:

```text
ownerOf(1) = addressCuenta3
balanceOf(addressCuenta3) = 1
tokenURI(1) = ipfs://CID_DE_LA_METADATA
tokenFinding(1) = 1
```

### Cómo verlo después en Sepolia/Etherscan

Cuando hagas lo mismo en Sepolia:

1. Abrir el contrato `WhitehatBadge` en Sepolia Etherscan.
2. Ir a `Read Contract`.
3. Ejecutar `tokenURI(1)`.
4. Copiar el resultado `ipfs://CID_DE_LA_METADATA`.
5. Convertirlo a gateway:

```text
https://gateway.pinata.cloud/ipfs/CID_DE_LA_METADATA
```

6. Abrir esa URL y verificar que el JSON tenga:

```json
"image": "ipfs://CID_DE_LA_IMAGEN"
```

7. Convertir la imagen a gateway:

```text
https://gateway.pinata.cloud/ipfs/CID_DE_LA_IMAGEN
```

Si ambas URLs abren bien, el NFT tiene metadata correcta.
