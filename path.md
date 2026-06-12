# Introducción breve

BugBountyShield es un MVP de bug bounty escrow on-chain. La idea es mostrar cómo una empresa puede dejar fondos bloqueados en un contrato, cómo un whitehat registra un finding usando solo el hash del reporte, y cómo un reviewer aprueba el hallazgo para que todo ocurra en una única transacción: se valida el finding, se paga la recompensa y se mintea un NFT soulbound de reputación. La demo está pensada para verse directamente en Etherscan, así queda claro qué pasa en cada contrato y cómo se conectan entre sí.

---

## Arquitectura del sistema

La arquitectura está separada en tres contratos para que cada responsabilidad quede aislada:

- `BountyEscrow`: es el contrato principal. Guarda los fondos, crea bounties, recibe findings, aprueba o rechaza reportes y paga recompensas.
- `FindingRegistry`: guarda la trazabilidad técnica del finding: bounty asociado, researcher, hash del reporte, severidad, estado y fecha.
- `WhitehatBadge`: maneja la reputación. Mintea el NFT/SBT cuando un finding es aprobado y bloquea las transferencias para que el badge quede ligado al whitehat.

La razón de separarlo así es que fondos, evidencia técnica y reputación no son la misma responsabilidad. Si todo estuviera en un solo contrato, sería más difícil de leer, auditar y mantener. Con esta división, cada contrato tiene un objetivo claro y `BountyEscrow` actúa como coordinador.

### Por qué hay interfaces

`BountyEscrow` no necesita conocer toda la implementación interna de `FindingRegistry` ni de `WhitehatBadge`. Solo necesita llamar algunas funciones concretas, por ejemplo:

```solidity
_findingRegistry.registerFinding(...)
_findingRegistry.validateFinding(...)
_whitehatBadge.mintBadge(...)
```

Para eso se usan las interfaces `IFindingRegistry` e `IWhitehatBadge`: definen el "contrato mínimo" que `BountyEscrow` espera poder llamar. Esto hace que la comunicación entre contratos sea más clara, reduce acoplamiento y permite cambiar una implementación siempre que respete la misma interfaz.

### Por qué aparece `Ownable`

`Ownable` viene de OpenZeppelin y agrega control de propietario. En este sistema se usa para operaciones administrativas, como configurar permisos o permitir que el owner también pueda actuar como reviewer. La idea es que no cualquier cuenta pueda aprobar findings, cambiar roles o ejecutar acciones sensibles.

En la demo, cuando se muestra `onlyReviewer`, se puede explicar que el acceso está restringido: solo el reviewer o el owner pueden aprobar un finding.

### Por qué aparece `ReentrancyGuard`

`ReentrancyGuard` también viene de OpenZeppelin y se usa para proteger funciones que mueven ETH. En `approveFinding`, la protección está en la firma:

```solidity
) external onlyReviewer nonReentrant {
```

Esto es importante porque al final de `approveFinding` se paga al whitehat con:

```solidity
(bool paid, ) = payable(finding.researcher).call{value: rewardAmount}("");
```

Si el `researcher` fuera un contrato malicioso, podría intentar reentrar durante esa transferencia. `nonReentrant` bloquea una segunda entrada mientras la primera llamada todavía está ejecutándose. Además, el contrato descuenta `remainingFunds` antes de enviar ETH, siguiendo el patrón checks-effects-interactions.

### Por qué aparece `Context`

`Context` aparece porque OpenZeppelin lo usa internamente como base de contratos como `Ownable` y `ERC721`. Sirve para abstraer datos de la llamada, principalmente `msg.sender` y `msg.data`, mediante funciones internas como `_msgSender()`.

En una demo simple parece innecesario, pero es parte de la arquitectura estándar de OpenZeppelin. Permite que contratos reutilizables manejen mejor casos avanzados, como meta-transacciones, sin depender directamente de `msg.sender` en todos lados.

Frase corta para decir:
> "Usamos OpenZeppelin para no reimplementar piezas sensibles: ownership, protección contra reentrancy y ERC721. Nuestro código se concentra en la lógica del bug bounty."

---

# BugBountyShield — Demo viernes (5 min)

## Estado pre-demo (ya hecho, no tocar)

```
FindingRegistry : 0xf9eA2a86502Cf5dae889A7863BDB6541E5340Bc0
WhitehatBadge   : 0x9A97534390b5254E4d2f50B720f879b948846C0D
BountyEscrow    : 0x8822AA8B00cEF6A1AE4e55e5e8AAe72945a09004

setEscrow  ✓
setMinter  ✓
Bounty ID 1 activo con 200000000000000000 wei (0.2 ETH) depositados ✓
Finding ID 1 y NFT ID 1 ya existen (demo anterior)
```

La demo de hoy genera **finding ID 2** y **NFT ID 2**.

Montos para usar en Etherscan/Sepolia:

```
Fondear bounty / Value   = 200000000000000000 wei = 0.2 ETH
Reward approveFinding    = 100000000000000000 wei = 0.1 ETH
```

Si Etherscan muestra selector de unidad en `Value`, elegir `Wei` y pegar el entero. Si se usa unidad `Ether`, poner `0.2`.

---

## Pestañas abiertas antes de entrar al aula

Abrí estas 4 pestañas en el navegador y dejálas listas:

```
1. https://sepolia.etherscan.io/address/0x8822AA8B00cEF6A1AE4e55e5e8AAe72945a09004#code
2. https://sepolia.etherscan.io/address/0xf9eA2a86502Cf5dae889A7863BDB6541E5340Bc0#readContract
3. https://sepolia.etherscan.io/address/0x9A97534390b5254E4d2f50B720f879b948846C0D#readContract
4. https://gateway.pinata.cloud/ipfs/bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
```

MetaMask: tener Cuenta 1 y la cuenta nueva del whitehat listas para cambiar rápido.

---

## Si hay que crear el bounty antes de la demo

Cuenta 1 → BountyEscrow → Write Contract → `createBounty`.

En el campo payable `Value` de Etherscan:

```
Value → 200000000000000000
Unit  → Wei
```
    
En `createBounty`:

```
title       →  Bug bounty Sepolia
description →  Bounty demo con premio bloqueado de 0.2 ETH
```

Resultado esperado en `getBounty(id)`:

```
depositedAmount → 200000000000000000
remainingFunds  → 200000000000000000
active          → true
```

Usar ese `bountyId` en `submitFinding`. En la demo preparada abajo se asume `bountyId = 1`.

---

## Demo (5 min exactos)

### Min 0:00 — Código verificado (BountyEscrow, pestaña 1)

Mostrar pestaña Contract → el código está verificado, señalar:
- `approveFinding` con el comentario de la cadena cross-contract
- El modificador `onlyReviewer`
- `nonReentrant`

Decir: *"BountyEscrow maneja los fondos y coordina los otros dos contratos."*

---

### Min 1:00 — Read Contract en vivo (BountyEscrow)

Ir a Write Contract → conectar MetaMask con **Cuenta 1** → cambiar a Read Contract.

Llamar estas 3:

```
getBounty(1)       →  muestra company, depositedAmount, remainingFunds, active=true
findingRegistry()  →  dirección de FindingRegistry
whitehatBadge()    →  dirección de WhitehatBadge
```

En `getBounty(1)`, revisar:

```
depositedAmount → 200000000000000000
remainingFunds  → al menos 100000000000000000
```

Decir: *"El bounty tiene 0.2 ETH bloqueados en el contrato. Los otros dos contratos están cableados desde el deploy."*

---

### Min 2:00 — submitFinding (cuenta nueva del whitehat)

Cambiar MetaMask a la **cuenta nueva (whitehat)**.

BountyEscrow → Write Contract → `submitFinding`:

```
bountyId   →  1
reportHash →  0x2222222222222222222222222222222222222222222222222222222222222222
severity   →  High
```

Confirmar en MetaMask. Esperar confirmación (~15 seg).

Decir: *"El whitehat registra el hash del reporte. El dato real queda off-chain, solo el hash queda on-chain."*

---

### Min 2:45 — approveFinding (Cuenta 1)

Cambiar MetaMask a **Cuenta 1**.

BountyEscrow → Write Contract → `approveFinding`:

```
findingId    →  2
rewardAmount →  100000000000000000
tokenURI     →  ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
```

Confirmar en MetaMask. Esperar confirmación.

Decir: *"Esta es la transacción principal — una sola tx dispara tres cosas."*

---

### Min 3:30 — Internal Txns (la tx de approveFinding)

Hacer click en el hash de la tx de approveFinding → pestaña **Internal Txns**.

Señalar las 3 líneas:
```
BountyEscrow → FindingRegistry   validateFinding()
BountyEscrow → WhitehatBadge     mintBadge()
BountyEscrow → cuenta whitehat   0.1 ETH
```

Decir: *"Etherscan muestra cada llamada interna. Un contrato llamó a los otros dos y también pagó ETH, todo atómico."*

---

### Min 4:15 — NFT y metadata

WhitehatBadge → Read Contract (pestaña 3):

```
ownerOf(2)    →  dirección del whitehat nuevo
tokenURI(2)   →  ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
```

Abrir pestaña 4 (Pinata) → mostrar el JSON → el campo `image` apunta al PNG.

Decir: *"El NFT es soulbound — no se puede transferir. Es reputación on-chain permanente."*

---

### Min 4:45 — Decisión de diseño (30 seg)

Decir:
> "Separamos en 3 contratos: BountyEscrow maneja fondos, FindingRegistry maneja trazabilidad técnica, WhitehatBadge maneja reputación. Cada uno es auditable en forma independiente y se puede actualizar sin tocar los otros."

---

## Cheatsheet de argumentos (tenerlo a mano)

```
submitFinding
  bountyId   = 1
  reportHash = 0x2222222222222222222222222222222222222222222222222222222222222222
  severity   = High

approveFinding
  findingId    = 2
  rewardAmount = 100000000000000000
  tokenURI     = ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a
```
