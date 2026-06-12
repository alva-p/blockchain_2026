# BugBountyShield — Tabla de Tests Manuales (Etapa 3)

Probados en Remix VM con 3 cuentas distintas y luego verificados en Sepolia Testnet.

---

| # | Contrato | Función | Inputs usados | Resultado esperado | Resultado obtenido | Estado |
|---|---|---|---|---|---|---|
| 1 | BountyEscrow | `createBounty` | title: "Bug bounty Sepolia", description: "Demo", value: 0.01 ETH, Cuenta 2 | Bounty ID 1 creado, ETH bloqueado, evento `BountyCreated` emitido | Bounty ID 1 creado, `depositedAmount = 10000000000000000`, `active = true` | ✓ |
| 2 | BountyEscrow | `createBounty` | value: 0 ETH (sin enviar ETH) | Revert `NoEtherSent` | Transacción revertida con `NoEtherSent` | ✓ |
| 3 | BountyEscrow | `createBounty` | title: "" (vacío), value: 0.01 ETH | Revert `EmptyTitle` | Transacción revertida con `EmptyTitle` | ✓ |
| 4 | BountyEscrow | `submitFinding` | bountyId: 1, reportHash: 0x1111...1111, severity: "High", Cuenta 3 | Finding ID 1 registrado en FindingRegistry, evento `FindingSubmitted` emitido | `getFinding(1)` devuelve researcher=Cuenta3, status=0 (Submitted) | ✓ |
| 5 | BountyEscrow | `submitFinding` | bountyId: 99 (inexistente) | Revert `InvalidBounty` | Transacción revertida con `InvalidBounty` | ✓ |
| 6 | BountyEscrow | `approveFinding` | findingId: 1, rewardAmount: 1000000000000000, tokenURI: ipfs://bafkrei..., Cuenta 1 | Finding validado, NFT minteado a Cuenta 3, 0.001 ETH transferido a Cuenta 3 | `getFinding(1)` status=1, `ownerOf(1)`=Cuenta3, balance Cuenta3 aumentó 0.001 ETH | ✓ |
| 7 | BountyEscrow | `approveFinding` | findingId: 1, desde Cuenta 2 (no reviewer) | Revert `NotReviewer` | Transacción revertida con `NotReviewer` | ✓ |
| 8 | BountyEscrow | `approveFinding` | findingId: 1, rewardAmount: 99 ETH (supera remainingFunds) | Revert `InsufficientFunds` | Transacción revertida con `InsufficientFunds` | ✓ |
| 9 | BountyEscrow | `cancelBounty` + `withdrawRemainingFunds` | bountyId: 1, Cuenta 2 cancela y retira fondos | Bounty cancelado, ETH restante devuelto a Cuenta 2 | `cancelled=true`, Cuenta 2 recibió fondos restantes | ✓ |
| 10 | FindingRegistry | `registerFinding` | Llamado directo desde Cuenta 1 (no es el escrow) | Revert `NotEscrow` | Transacción revertida con `NotEscrow` | ✓ |
| 11 | FindingRegistry | `getFinding` | findingId: 1 (existente) | Devuelve datos del finding: researcher, severity, status, bountyId | Retorna struct completo con todos los campos correctos | ✓ |
| 12 | FindingRegistry | `setEscrow` | newEscrow: 0x000...000 (address cero) | Revert `ZeroAddress` | Transacción revertida con `ZeroAddress` | ✓ |
| 13 | WhitehatBadge | `mintBadge` | Llamado directo desde Cuenta 1 (no es el minter) | Revert `NotMinter` | Transacción revertida con `NotMinter` | ✓ |
| 14 | WhitehatBadge | `approve` | tokenId: 1, to: Cuenta 2 (intento de transferir) | Revert `SoulboundToken` | Transacción revertida con `SoulboundToken` | ✓ |
| 15 | WhitehatBadge | `setApprovalForAll` | operator: Cuenta 2, approved: true | Revert `SoulboundToken` | Transacción revertida con `SoulboundToken` | ✓ |
| 16 | WhitehatBadge | `tokenURI` | tokenId: 1 | Devuelve `ipfs://bafkreih6sfxpc5w3oy4jpkzxidoelubhrf3qynv3koqw4ovxij4fv3tq5a` | URI IPFS correcta, metadata JSON accesible en gateway de Pinata | ✓ |

---

## Notas

- Todos los tests fueron ejecutados primero en **Remix VM** con 3 cuentas simuladas antes del deploy en Sepolia.
- Los tests 6 y 16 fueron verificados adicionalmente en **Sepolia Testnet** con MetaMask.
- El test 6 (`approveFinding`) valida la interacción cross-contract completa: BountyEscrow → FindingRegistry → WhitehatBadge → ETH transfer, visible en la pestaña Internal Txns de Etherscan.
- Los badges son **soulbound**: los tests 14 y 15 verifican que no se pueden transferir ni aprobar operadores.
