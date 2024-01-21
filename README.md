# CodeStreisand

<details><summary>How to restore</summary>

## General instructions

1. Clone the `archive` branch

```bash
git clone --branch archive https://github.com/your-username/your-repo codestreisand
```

2. Restore from bundle

```bash
git clone codestreisand/FILE.bundle
```

## Download only a specific backup

```bash
git clone --no-checkout --depth=1 --no-tags --branch archive https://github.com/your-username/your-repo codestreisand
git -C codestreisand restore --staged FILE.bundle
git -C codestreisand checkout FILE.bundle
git clone codestreisand/FILE.bundle
```

</details>

| Status | Name | Software Heritage | Last Update |
| - | - | - | - |
| 🟩 | [hon](https://github.com/Andre0512/hon) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/Andre0512/hon) | 21/01/2024 |
| 🟩 | [pyhOn](https://github.com/Andre0512/pyhOn) | [Link](https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/Andre0512/pyhOn) | 21/01/2024 |
