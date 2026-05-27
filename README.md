# BugBountyShield

BugBountyShield es un MVP de Bug Bounty Escrow on-chain para un Trabajo Práctico Integrador de contratos inteligentes. Una empresa crea un bounty depositando ETH, un whitehat registra un finding con el hash del reporte y un reviewer aprueba o rechaza. Si se aprueba, el contrato valida el finding, paga ETH al whitehat y mintea un NFT/SBT de reputación.

El proyecto está pensado para usarse manualmente desde Remix Ethereum IDE, MetaMask y Etherscan. No requiere Hardhat, Foundry, scripts de deploy ni frontend.

## Arquitectura

```text
BugBountyShield/
├── contracts/
│   ├── BountyEscrow.sol
│   ├── FindingRegistry.sol
│   ├── WhitehatBadge.sol
│   └── interfaces/
│       ├── IFindingRegistry.sol
│       └── IWhitehatBadge.sol
├── assets/
│   └── vitalik.png
├── metadata/
│   └── whitehat-badge-metadata.example.json
├── docs/
│   └── BugBountyShield_Guia.md
└── README.md
```

## Contratos

### BountyEscrow

Contrato principal. Recibe ETH, crea bounties, permite registrar findings a través de `FindingRegistry`, aprueba o rechaza findings, paga recompensas, mintea badges y permite cancelar bounties con retiro de fondos restantes.

### FindingRegistry

Registro técnico de findings. Guarda `id`, `bountyId`, `researcher`, `reportHash`, `severity`, `status` y `createdAt`. Solo `BountyEscrow` puede registrar, validar o rechazar findings.

### WhitehatBadge

NFT ERC721 de reputación. Cada token guarda `tokenURI` y se vincula a un `findingId`. Es soulbound: no puede transferirse ni aprobarse.

## Flujo principal

```text
Empresa -> BountyEscrow.createBounty(...) + ETH
Whitehat -> BountyEscrow.submitFinding(...)
Reviewer -> BountyEscrow.approveFinding(...)
  -> FindingRegistry.validateFinding(...)
  -> WhitehatBadge.mintBadge(whitehat que envió el finding, findingId, tokenURI)
  -> pago ETH al whitehat
```

El NFT siempre se mintea a la dirección que ejecutó `submitFinding`. Esa dirección queda guardada como `researcher` en `FindingRegistry`, y `approveFinding` usa ese dato para pagar y mintear el badge.

## Orden de deploy en Remix

1. Deployar `FindingRegistry`.
2. Deployar `WhitehatBadge`.
3. Deployar `BountyEscrow`, pasando:

```text
findingRegistry = dirección de FindingRegistry
whitehatBadge = dirección de WhitehatBadge
```

4. Ejecutar:

```text
FindingRegistry.setEscrow(addressBountyEscrow)
WhitehatBadge.setMinter(addressBountyEscrow)
```

## Ejemplo de uso en Remix VM

Roles:

- Cuenta 1: admin/reviewer.
- Cuenta 2: empresa.
- Cuenta 3: whitehat.

### Crear bounty

Con Cuenta 2, enviar `1 ETH` en `Value`:

```text
createBounty(
  "Bug bounty MVP",
  "Programa de prueba para reportes validos"
)
```

### Registrar finding

Con Cuenta 3:

```text
submitFinding(
  1,
  0x1111111111111111111111111111111111111111111111111111111111111111,
  "High"
)
```

### Aprobar finding

Con Cuenta 1:

```text
approveFinding(
  1,
  100000000000000000,
  "ipfs://CID_DE_LA_METADATA"
)
```

El reward del ejemplo es `0.1 ETH`.

Al aprobar, el NFT se entrega a Cuenta 3 porque Cuenta 3 fue quien registró el finding. El reviewer no elige manualmente el receptor del NFT.

## Metadata IPFS

La imagen del NFT está en:

```text
assets/vitalik.png
```

Pasos:

1. Subir `assets/vitalik.png` a Pinata.
2. Copiar el CID de la imagen.
3. Editar `metadata/whitehat-badge-metadata.example.json`.
4. Reemplazar:

```text
ipfs://CID_DE_LA_IMAGEN
```

por el CID real de la imagen.

5. Subir el JSON a Pinata.
6. Copiar el CID de la metadata.
7. Usar esta URI en `approveFinding`:

```text
ipfs://CID_DE_LA_METADATA
```

Importante: `tokenURI` apunta al JSON de metadata, no a la imagen directa.

## Verificar NFT

Después de aprobar:

```text
WhitehatBadge.balanceOf(addressWhitehat)
WhitehatBadge.ownerOf(1)
WhitehatBadge.tokenURI(1)
WhitehatBadge.tokenFinding(1)
```

Resultados esperados:

- `balanceOf(addressWhitehat) = 1`
- `ownerOf(1) = addressWhitehat`
- `tokenURI(1) = ipfs://CID_DE_LA_METADATA`
- `tokenFinding(1) = 1`

## Checklist de demo

- Compilar contratos en Remix con Solidity `0.8.20` o superior.
- Deployar `FindingRegistry`.
- Deployar `WhitehatBadge`.
- Deployar `BountyEscrow`.
- Configurar `setEscrow`.
- Configurar `setMinter`.
- Crear bounty con Cuenta 2 y ETH.
- Registrar finding con Cuenta 3.
- Aprobar finding con Cuenta 1.
- Mostrar `getBounty`.
- Mostrar `getFinding`.
- Mostrar `ownerOf`, `balanceOf` y `tokenURI`.
- Mostrar tx hash de `approveFinding` como evidencia cross-contract.
- Mostrar contratos verificados en Sepolia Etherscan.

## Documentación completa

Ver [docs/BugBountyShield_Guia.md](docs/BugBountyShield_Guia.md).
