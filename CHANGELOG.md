# [1.0.0-beta.8](https://github.com/BNLNPPS/esi-shell/compare/1.0.0-beta.7...1.0.0-beta.8) (2024-05-13)


### Bug Fixes

* **env:** load xerces-c, update PATH ([#66](https://github.com/BNLNPPS/esi-shell/issues/66)) ([044e0ba](https://github.com/BNLNPPS/esi-shell/commit/044e0ba7bff3e4c3e4d3465376341cd7fcddddde))

# [1.0.0-beta.7](https://github.com/BNLNPPS/esi-shell/compare/1.0.0-beta.6...1.0.0-beta.7) (2024-05-10)


### Bug Fixes

* always pull updated image from registry ([#62](https://github.com/BNLNPPS/esi-shell/issues/62)) ([33f5b06](https://github.com/BNLNPPS/esi-shell/commit/33f5b0614ecd4ce3918492c22a087aa395767932))

# [1.0.0-beta.6](https://github.com/BNLNPPS/esi-shell/compare/1.0.0-beta.5...1.0.0-beta.6) (2024-05-07)


### Features

* build gpu code dependent on OptiX, run opticks tests ([#49](https://github.com/BNLNPPS/esi-shell/issues/49)) ([#53](https://github.com/BNLNPPS/esi-shell/issues/53)) ([5f58b7b](https://github.com/BNLNPPS/esi-shell/commit/5f58b7be7d1893ba7247de5b95f43a7349aa4cf8)), closes [#50](https://github.com/BNLNPPS/esi-shell/issues/50)

# [1.0.0-beta.5](https://github.com/BNLNPPS/esi-shell/compare/1.0.0-beta.4...1.0.0-beta.5) (2024-05-07)


### Reverts

* Revert "feat: build gpu code dependent on OptiX, run opticks tests (#49)" ([a301bd2](https://github.com/BNLNPPS/esi-shell/commit/a301bd290c43476ef5fa674ce7cc52f326fa29e9)), closes [#49](https://github.com/BNLNPPS/esi-shell/issues/49)

# [1.0.0-beta.4](https://github.com/BNLNPPS/esi-shell/compare/1.0.0-beta.3...1.0.0-beta.4) (2024-05-06)


### Features

* update opticks ([#42](https://github.com/BNLNPPS/esi-shell/issues/42)) ([4338f7c](https://github.com/BNLNPPS/esi-shell/commit/4338f7c51bb92b643bfbef9cb32920d517f26395)), closes [#41](https://github.com/BNLNPPS/esi-shell/issues/41)


### Reverts

* restore removed pull of latest image for cache purposes ([#47](https://github.com/BNLNPPS/esi-shell/issues/47)) ([8138919](https://github.com/BNLNPPS/esi-shell/commit/8138919d14d20646535e0c80c1e1266c04e9543b))

# [1.0.0-beta.3](https://github.com/BNLNPPS/esi-opticks/compare/1.0.0-beta.2...1.0.0-beta.3) (2024-05-03)


### Features

* upgrade opticks ([#39](https://github.com/BNLNPPS/esi-opticks/issues/39)) ([2d6706a](https://github.com/BNLNPPS/esi-opticks/commit/2d6706a0ccf8bb79b55a538c1437464ab5462648))

# [1.0.0-beta.2](https://github.com/BNLNPPS/esi-opticks/compare/1.0.0-beta.1...1.0.0-beta.2) (2024-04-26)


### Bug Fixes

* **eic-shell:** switch to ghcr.io registry ([928acba](https://github.com/BNLNPPS/esi-opticks/commit/928acba495e3865e5d986e899de8993abcd63768))
* remove container after tests ([105a4ba](https://github.com/BNLNPPS/esi-opticks/commit/105a4ba3d2de5db92c96e451a40e5fcc50a96a4d))

# 1.0.0-beta.1 (2024-04-26)


### Bug Fixes

* **build:** keep build cache dir ([#21](https://github.com/BNLNPPS/esi-opticks/issues/21)) ([d81672d](https://github.com/BNLNPPS/esi-opticks/commit/d81672d8f4a08532e2719851320ee9e3112cb5a5))
* **esi-shell:** avoid building code (OptiX) on shell startup ([#23](https://github.com/BNLNPPS/esi-opticks/issues/23)) ([76320cf](https://github.com/BNLNPPS/esi-opticks/commit/76320cf6e8d43e37414d0469ae8f81c950f97231))
* **esi-shell:** drop support for singularity with GPU (for now) ([#22](https://github.com/BNLNPPS/esi-opticks/issues/22)) ([4cb9d19](https://github.com/BNLNPPS/esi-opticks/commit/4cb9d19c3180ac66aab8d58a4e615cd4e0e6567e))
* **esi-shell:** improve user experience ([#20](https://github.com/BNLNPPS/esi-opticks/issues/20)) ([0a464af](https://github.com/BNLNPPS/esi-opticks/commit/0a464af1dd9d01cedb98dd50b3f3681dbe73da22))
* **esi-shell:** support only linux ([#13](https://github.com/BNLNPPS/esi-opticks/issues/13)) ([6cfb154](https://github.com/BNLNPPS/esi-opticks/commit/6cfb154d82fe252089b10ef92db3a63707c2a60b))
* patch spack default modules.yaml ([#27](https://github.com/BNLNPPS/esi-opticks/issues/27)) ([23183af](https://github.com/BNLNPPS/esi-opticks/commit/23183af24648db3fdcdf0c5a9dc94385d9aa1b9c))
* set compute capability to 5.2 compatible with Quadro M4000 ([#1](https://github.com/BNLNPPS/esi-opticks/issues/1)) ([b1d7513](https://github.com/BNLNPPS/esi-opticks/commit/b1d751357c61ac3e18a94262536ca397d1fa54e7))
* simplify build workflow, leverage login scripts ([#8](https://github.com/BNLNPPS/esi-opticks/issues/8)) ([fd974b4](https://github.com/BNLNPPS/esi-opticks/commit/fd974b4c42dbcb8c1247cd262bafbf16e4eb071b))
* use correct gdml file ([c014536](https://github.com/BNLNPPS/esi-opticks/commit/c014536e4452a815bef61a2b03bfe456a898bb7d))


### Features

* add esi-shell ([#6](https://github.com/BNLNPPS/esi-opticks/issues/6)) ([fa859aa](https://github.com/BNLNPPS/esi-opticks/commit/fa859aa91496b27fb66d891ef78a28ec90b45c50))
* setup semantic release ([ca0553c](https://github.com/BNLNPPS/esi-opticks/commit/ca0553c24acb7da072314c1b4f31bc3a84d79460))
* upgrade opticks to main@b55f15bd ([#26](https://github.com/BNLNPPS/esi-opticks/issues/26)) ([946da36](https://github.com/BNLNPPS/esi-opticks/commit/946da36cdc7fe309c63a8547ca8aeeeb0551a313))
