# BugBountyShield - Paso a paso en Sepolia

Esta guía es para ejecutar el flujo completo en Sepolia usando Remix, MetaMask y Etherscan.

## 1. CIDs IPFS del NFT

Según `address.md`, los CIDs son:

```text
CID JSON: bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
CID PNG:  bafybeigd55vk45nkme6baku6vli2n7txwwc52zvesfbywecxhrcovfr2ki
```

La URI que se usa en el contrato es la del JSON:

```text
ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
```

No usar el CID del PNG directamente en `approveFinding`. El PNG va dentro del JSON de metadata.

Para revisar los archivos en navegador:

```text
Metadata JSON:
https://gateway.pinata.cloud/ipfs/bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a

Imagen PNG:
https://gateway.pinata.cloud/ipfs/bafybeigd55vk45nkme6baku6vli2n7txwwc52zvesfbywecxhrcovfr2ki
```

## 2. Roles

Usar tres cuentas distintas de MetaMask:

```text
Cuenta 1 = admin / reviewer / deployer
Cuenta 2 = empresa que crea el bounty y deposita ETH
Cuenta 3 = whitehat que registra el finding y recibe ETH + NFT
```

Las tres cuentas que firmen transacciones necesitan algo de Sepolia ETH para gas.

## 3. Conectar Remix a Sepolia

1. Abrir MetaMask.
2. Seleccionar la red `Sepolia`.
3. Abrir Remix.
4. Ir a `Deploy & Run Transactions`.
5. En `Environment`, elegir:

```text
Injected Provider - MetaMask
```

6. Aceptar la conexión en MetaMask.
7. Verificar que Remix muestre la cuenta de MetaMask y que la red sea Sepolia.

## 4. Deploy con Cuenta 1

Seleccionar Cuenta 1 en MetaMask.

Deployar en este orden:

1. `FindingRegistry`
2. `WhitehatBadge`
3. `BountyEscrow`

Para deployar `BountyEscrow`, el constructor pide:

```text
findingRegistryAddress = dirección de FindingRegistry
whitehatBadgeAddress = dirección de WhitehatBadge
```

En Remix se puede pegar como:

```text
"0xDireccionFindingRegistry","0xDireccionWhitehatBadge"
```

Guardar:

```text
Dirección FindingRegistry:
Dirección WhitehatBadge:
Dirección BountyEscrow:
Tx deploy FindingRegistry:
Tx deploy WhitehatBadge:
Tx deploy BountyEscrow:
```

## 5. Configurar permisos con Cuenta 1

Esto es obligatorio.

En `FindingRegistry`, ejecutar:

```text
setEscrow(addressBountyEscrow)
```

En `WhitehatBadge`, ejecutar:

```text
setMinter(addressBountyEscrow)
```

Verificar:

```text
FindingRegistry.escrow()
WhitehatBadge.minter()
```

Ambos deben devolver la dirección de `BountyEscrow`.

Guardar:

```text
Tx setEscrow:
Tx setMinter:
```

## 6. Crear bounty con Cuenta 2

Cambiar MetaMask a Cuenta 2.

En Remix:

1. Verificar que `Account` sea Cuenta 2.
2. En `Value`, poner:

```text
0.01
```

3. En unidad, elegir:

```text
ether
```

4. En `BountyEscrow`, ejecutar:

```text
createBounty(
  "Bug bounty Sepolia",
  "Bounty de prueba para validar reporte y mintear NFT"
)
```

Si Remix pide los argumentos en una sola línea:

```text
"Bug bounty Sepolia","Bounty de prueba para validar reporte y mintear NFT"
```

Confirmar en MetaMask.

Verificar:

```text
BountyEscrow.getBounty(1)
BountyEscrow.getRemainingFunds(1)
```

Resultado esperado:

```text
company = dirección de Cuenta 2
depositedAmount = 10000000000000000
remainingFunds = 10000000000000000
active = true
cancelled = false
```

`10000000000000000 wei = 0.01 ETH`.

Guardar:

```text
Tx createBounty:
Bounty ID: 1
```

## 7. Registrar finding con Cuenta 3

Cambiar MetaMask a Cuenta 3.

En Remix:

1. Verificar que `Account` sea Cuenta 3.
2. En `Value`, poner:

```text
0
```

3. En `BountyEscrow`, ejecutar:

```text
submitFinding(
  1,
  0x1111111111111111111111111111111111111111111111111111111111111111,
  "High"
)
```

Si Remix pide los argumentos en una sola línea:

```text
1,0x1111111111111111111111111111111111111111111111111111111111111111,"High"
```

Confirmar en MetaMask.

Verificar en `FindingRegistry`:

```text
getFinding(1)
```

Resultado esperado:

```text
id = 1
bountyId = 1
researcher = dirección de Cuenta 3
reportHash = 0x1111111111111111111111111111111111111111111111111111111111111111
severity = High
status = 0
```

`status = 0` significa `Submitted`.

Guardar:

```text
Tx submitFinding:
Finding ID: 1
Whitehat / researcher: dirección de Cuenta 3
```

## 8. Aprobar finding con Cuenta 1

Cambiar MetaMask a Cuenta 1.

En Remix:

1. Verificar que `Account` sea Cuenta 1.
2. En `Value`, poner:

```text
0
```

3. En `BountyEscrow`, ejecutar:

```text
approveFinding(
  1,
  1000000000000000,
  "ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a"
)
```

Si Remix pide los argumentos en una sola línea:

```text
1,1000000000000000,"ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a"
```

Ese reward es:

```text
1000000000000000 wei = 0.001 ETH
```

Confirmar en MetaMask.

Esta es la transacción principal de la demo porque ejecuta la interacción cross-contract:

```text
BountyEscrow.approveFinding()
  -> FindingRegistry.validateFinding()
  -> WhitehatBadge.mintBadge()
  -> pago ETH al whitehat
```

Guardar:

```text
Tx approveFinding:
Token URI usado: ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
Reward pagado: 0.001 ETH
```

## 9. Verificar finding validado

En `FindingRegistry`, ejecutar:

```text
getFinding(1)
```

Resultado esperado:

```text
status = 1
```

`status = 1` significa `Validated`.

## 10. Verificar pago al whitehat

Revisar el balance de Cuenta 3 en MetaMask o en Sepolia Etherscan.

Cuenta 3 debe haber recibido aproximadamente:

```text
0.001 ETH
```

Cuenta 3 no paga gas en la aprobación porque la transacción `approveFinding` la ejecuta Cuenta 1.

## 11. Verificar NFT minteado al whitehat

En `WhitehatBadge`, ejecutar:

```text
ownerOf(1)
```

Debe devolver:

```text
dirección de Cuenta 3
```

Luego ejecutar:

```text
balanceOf(addressCuenta3)
tokenURI(1)
tokenFinding(1)
```

Resultado esperado:

```text
balanceOf(addressCuenta3) = 1
tokenURI(1) = ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
tokenFinding(1) = 1
```

Esto demuestra que:

```text
El finding 1 fue validado.
La Cuenta 3 recibió ETH.
La Cuenta 3 recibió el NFT de reputación.
El NFT apunta a la metadata IPFS correcta.
```

## 12. Verificar metadata e imagen

Abrir:

```text
https://gateway.pinata.cloud/ipfs/bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
```

El JSON debe tener una línea similar a:

```json
"image": "ipfs://bafybeigd55vk45nkme6baku6vli2n7txwwc52zvesfbywecxhrcovfr2ki"
```

Abrir la imagen:

```text
https://gateway.pinata.cloud/ipfs/bafybeigd55vk45nkme6baku6vli2n7txwwc52zvesfbywecxhrcovfr2ki
```

Debe verse el badge del NFT.

## 13. Evidencia para la entrega

Completar esta tabla:

| Dato | Valor |
|---|---|
| Dirección FindingRegistry | |
| Dirección WhitehatBadge | |
| Dirección BountyEscrow | |
| URL Etherscan FindingRegistry | `https://sepolia.etherscan.io/address/` |
| URL Etherscan WhitehatBadge | `https://sepolia.etherscan.io/address/` |
| URL Etherscan BountyEscrow | `https://sepolia.etherscan.io/address/` |
| Tx deploy FindingRegistry | |
| Tx deploy WhitehatBadge | |
| Tx deploy BountyEscrow | |
| Tx setEscrow | |
| Tx setMinter | |
| Tx createBounty | |
| Tx submitFinding | |
| Tx approveFinding cross-contract | |
| Whitehat que recibió NFT | Dirección de Cuenta 3 |
| Token ID minteado | `1` |
| Token URI | `ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a` |
| CID JSON | `bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a` |
| CID PNG | `bafybeigd55vk45nkme6baku6vli2n7txwwc52zvesfbywecxhrcovfr2ki` |

## 14. Resumen para la exposición

Decir:

```text
La empresa depositó ETH en BountyEscrow.
El whitehat registró un finding con el hash del reporte.
El reviewer validó el finding.
Al aprobarlo, BountyEscrow llamó a FindingRegistry para validarlo,
llamó a WhitehatBadge para mintear el NFT,
y pagó ETH al whitehat.
```

La decisión de diseño clave:

```text
Separamos responsabilidades: BountyEscrow maneja fondos,
FindingRegistry maneja trazabilidad técnica y WhitehatBadge maneja reputación.
Esto hace que el sistema sea más fácil de auditar, mantener y demostrar en Etherscan.
```
