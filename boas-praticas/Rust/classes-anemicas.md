# O Anti-Pattern das Classes Anêmicas e o Modelo Rico em Rust

> O Modelo de Domínio Anêmico (*Anemic Domain Model*) é um dos antipadrões arquiteturais mais disseminados no desenvolvimento corporativo moderno. Ele ocorre quando criamos estruturas de dados que contêm apenas atributos desprotegidos (ou meros *getters* e *setters* mecânicos), enquanto toda a inteligência, regras de negócio e validações são terceirizadas para classes de serviço procedurais.

Descrito criticamente por Martin Fowler em 2003, esse padrão subverte o princípio fundamental da modelagem orientada a domínio: **unir dados e comportamento na mesma unidade conceitual**.

Embora o Rust não seja uma linguagem de Programação Orientada a Objetos clássica (dispensa herança de classes em favor de composição, *traits* e sistemas de tipos algébricos), a linguagem oferece o ecossistema perfeito para implementar **Modelos Ricos** (*Rich Domain Models*), garantindo invariantes de negócio diretamente em tempo de compilação.

---

## 1. Por que a POO corporativa tradicional adoeceu de anemia?

O surgimento massivo de classes anêmicas em ecossistemas como Java, C# e PHP não foi um acidente, mas o resultado de três pressões de design:

1. **Separação Artificial (Dados vs. Comportamento):** Padrões arquiteturais mal interpretados passaram a ditar que "entidades guardam dados" e "services guardam lógica". Uma entidade `ContaBancaria` vira uma mera sacola de propriedades, enquanto `ContaBancariaService` orquestra regras que deveriam ser intrínsecas à própria conta. O resultado prático é **código procedural fantasiado de POO**.
2. **Requisitos de Mapeadores Objeto-Relacionais (ORMs):** Ferramentas pioneiras de persistência (como Hibernate, JPA e Entity Framework clássico) exigiam construtores padrão sem argumentos (`new()`) e métodos `get`/`set` públicos em todos os campos para conseguir instanciar e hidratar tabelas de banco de dados por reflexão (*reflection*).
3. **Cultura do "Encapsulamento Teatral":** Tornar todos os campos privados mas gerar automaticamente *getters* e *setters* públicos para cada um deles cria apenas uma ilusão de encapsulamento. Qualquer consumidor externo pode chamar `conta.set_saldo(-50000.00)` a qualquer momento.

---

## 2. Tabela Comparativa: Modelo Anêmico vs. Modelo Rico (DDD)

| Aspecto | Modelo Anêmico (*Anemic Model*) | Modelo Rico / DDD (*Rich Domain Model*) |
| :--- | :--- | :--- |
| **Onde reside a lógica?** | Em classes externas (`Service`, `Helper`, `Manager`, `Controller`). | Encapsulada dentro do próprio tipo/entidade que detém os dados. |
| **Garantia de Invariantes** | Nenhuma. O objeto pode existir em memória em estado inválido, corrompido ou parcial. | Total. O construtor e os métodos garantem que o tipo **nunca** atinja um estado inválido. |
| **Acesso a Atributos** | *Getters* e *Setters* públicos universais (`set_status`, `set_saldo`). | Campos privados; mutações ocorrem apenas através de verbos de domínio expressivos (`sacar`, `depositar`, `cancelar`). |
| **Estilo Arquitetural** | Procedural disfarçado com classes (`Transaction Script`). | Orientado a Domínio legítimo (*Domain-Driven Design*). |
| **Tratamento em Rust** | `pub struct` com todos os campos `pub`, modificados livremente por qualquer módulo. | `struct` com campos privados, construtores inteligentes (*Smart Constructors*) e métodos que retornam `Result`. |

---

## 3. Na Prática: Do Modelo Anêmico ao Modelo Rico em Rust

### ❌ Abordagem Anêmica (Campos públicos ou mutação externa desprotegida)

No exemplo anêmico, a estrutura `ContaBancaria` é uma mera gaveta de valores. A regra de negócio que impede saque sem saldo suficiente reside no serviço:

```rust
// ❌ ANÊMICO: Estrutura sem proteção
pub struct ContaBancaria {
    pub titular: String,
    pub saldo: f64, // Qualquer arquivo do projeto pode fazer: conta.saldo = -9999.0;
}

// ❌ ANÊMICO: Toda a inteligência foi drenada para um "Service" externo
pub struct ContaBancariaService;

impl ContaBancariaService {
    pub fn sacar(conta: &mut ContaBancaria, valor: f64) -> Result<(), &'static str> {
        if valor <= 0.0 {
            return Err("Valor de saque deve ser positivo.");
        }
        if conta.saldo < valor {
            return Err("Saldo insuficiente.");
        }
        conta.saldo -= valor;
        Ok(())
    }
}
```

> [!WARNING]
> **O perigo da anemia:** Se um novo desenvolvedor instanciar `ContaBancaria` em outro módulo e subtrair o saldo diretamente sem invocar `ContaBancariaService::sacar`, o sistema aceitará saldo negativo sem emitir nenhum aviso ou erro. A integridade do sistema depende da boa vontade e disciplina dos programadores, não do compilador.

---

### ✅ Abordagem Rica (Encapsulamento, Invariantes e Erros Tipados)

No modelo rico em Rust, os campos são mantidos **privados** ao módulo da entidade. Não existem *setters* arbitrários; apenas operações de negócio que respeitam invariantes:

```rust
// ✅ RICO: Erro de domínio fortemente tipado
#[derive(Debug, PartialEq, Eq)]
pub enum ErroOperacaoBancaria {
    ValorInvalido(String),
    SaldoInsuficiente { saldo_atual: i64, valor_solicitado: i64 },
    TitularInvalido,
}

// ✅ RICO: Entidade com campos privados garantindo integridade
pub struct ContaBancaria {
    titular: String,
    // Representado em centavos (i64) para evitar imprecisões de ponto flutuante
    saldo_centavos: i64,
}

impl ContaBancaria {
    /// Smart Constructor: Impossível criar uma conta com titular vazio ou saldo negativo
    pub fn abrir(titular: impl Into<String>, deposito_inicial_centavos: i64) -> Result<Self, ErroOperacaoBancaria> {
        let titular = titular.into().trim().to_string();
        if titular.is_empty() {
            return Err(ErroOperacaoBancaria::TitularInvalido);
        }
        if deposito_inicial_centavos < 0 {
            return Err(ErroOperacaoBancaria::ValorInvalido("Depósito inicial não pode ser negativo.".into()));
        }

        Ok(Self {
            titular,
            saldo_centavos: deposito_inicial_centavos,
        })
    }

    /// Comportamento encapsulado que protege a invariante de saldo
    pub fn sacar(&mut self, valor_centavos: i64) -> Result<(), ErroOperacaoBancaria> {
        if valor_centavos <= 0 {
            return Err(ErroOperacaoBancaria::ValorInvalido("Valor de saque deve ser estritamente positivo.".into()));
        }
        if self.saldo_centavos < valor_centavos {
            return Err(ErroOperacaoBancaria::SaldoInsuficiente {
                saldo_atual: self.saldo_centavos,
                valor_solicitado: valor_centavos,
            });
        }

        self.saldo_centavos -= valor_centavos;
        Ok(())
    }

    /// Depósito seguro
    pub fn depositar(&mut self, valor_centavos: i64) -> Result<(), ErroOperacaoBancaria> {
        if valor_centavos <= 0 {
            return Err(ErroOperacaoBancaria::ValorInvalido("Valor de depósito deve ser positivo.".into()));
        }

        self.saldo_centavos += valor_centavos;
        Ok(())
    }

    // Apenas getters de leitura (imutáveis). ZERO setters públicos
    pub fn titular(&self) -> &str {
        &self.titular
    }

    pub fn saldo_centavos(&self) -> i64 {
        self.saldo_centavos
    }
}
```

---

## 4. O Princípio *Parse, Don't Validate*

Em sistemas tradicionais com modelos anêmicos, você frequentemente vê funções que apenas checam booleanos:

```rust
// ❌ Estilo ingênuo: apenas valida e descarta o conhecimento adquirido
fn validar_email(email: &str) -> bool { /* ... */ }

fn enviar_boas_vindas(email: String) {
    if !validar_email(&email) {
        panic!("E-mail inválido!");
    }
    // O resto da aplicação continua recebendo uma String genérica desprotegida...
}
```

Em Rust, o paradigma preconizado por Alexis King é **"Parse, Don't Validate"** (Faça *parse*, não apenas valide). Em vez de retornar um `bool` e continuar passando uma string desprotegida para todo o sistema, transformamos o dado bruto em um **Value Object tipado**:

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn parse(valor: impl Into<String>) -> Result<Self, &'static str> {
        let valor = valor.into().trim().to_string();
        if !valor.contains('@') || valor.len() < 5 {
            return Err("Formato de e-mail inválido.");
        }
        Ok(Self(valor))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}
```

> [!TIP]
> Uma vez que uma instância de `Email` existe na memória, **nenhuma outra função do sistema precisa testar se ela é válida novamente**. O compilador do Rust atua como guardião do domínio.

---

## 5. DTOs e "Hidratação" em Rust: Serde e Extractors na Web

Uma dúvida frequente de desenvolvedores vindos de PHP (Doctrine/Laravel), Java (Spring/Hibernate) ou C# (.NET) é:

> *"Se eu tornar os atributos privados no meu modelo rico, como os frameworks web e bancos de dados vão popular os dados vindos de requisições HTTP (Hydration)?"*

No ecossistema Rust:
1. **Não usamos reflexão em tempo de execução (*zero reflection*):** A biblioteca `serde` gera código de desserialização em tempo de compilação.
2. **DTOs são cidadãos de primeira classe na borda (*Boundary*):** O DTO (*Data Transfer Object*) é uma struct desacoplada, cujos campos podem ser públicos ou configurados para receber payloads HTTP/JSON/Formulários.
3. **A fronteira de conversão é tipada:** O DTO é consumido e convertido para a Entidade Rica via traits padrão como `TryFrom`.

```
Requisição HTTP (JSON / Form)
           │
           ▼
     [ DTO Serde ]          <── Extractor do Framework (Axum / Actix)
(Campos públicos na borda)
           │
           ▼  TryFrom / Construtor de Domínio
  [ Entidade Rica ]         <── Campos privados, validações de negócio,
 (Coração da Aplicação)          invariantes blindadas
```

### Exemplo Completo com Axum:

#### 1. O DTO de Entrada (Borda da API)
```rust
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct CadastroContaRequestDto {
    pub titular: String,
    pub deposito_inicial: f64,
}
```

#### 2. A Ponte Segura com `TryFrom`
```rust
impl TryFrom<CadastroContaRequestDto> for ContaBancaria {
    type Error = ErroOperacaoBancaria;

    fn try_from(dto: CadastroContaRequestDto) -> Result<Self, Self::Error> {
        let centavos = (dto.deposito_inicial * 100.0).round() as i64;
        ContaBancaria::abrir(dto.titular, centavos)
    }
}
```

#### 3. O Handler Axum Limpo e Sem Lógica Repetida
```rust
use axum::{
    extract::Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};

pub async fn criar_conta_handler(
    Json(payload): Json<CadastroContaRequestDto>,
) -> Result<StatusCode, (StatusCode, String)> {
    // A conversão pelo TryFrom força a validação das invariantes de domínio
    let conta = ContaBancaria::try_from(payload)
        .map_err(|err| (StatusCode::UNPROCESSABLE_ENTITY, format!("Erro de domínio: {:?}", err)))?;

    println!("Conta de {} criada com sucesso com saldo R$ {:.2}!", conta.titular(), conta.saldo_centavos() as f64 / 100.0);

    Ok(StatusCode::CREATED)
}
```

---

## 6. O Nível Supremo de Modelo Rico: *Type State Pattern*

O Rust permite levar o Modelo Rico ainda além da POO tradicional através de **Máquinas de Estado em Tempo de Compilação** (*Type State Pattern*). Com esse padrão, métodos só existem quando a entidade está no estado correto:

```rust
// Estados como tipos zero-cost (PhantomData)
pub struct Rascunho;
pub struct Publicado;

pub struct Artigo<Estado> {
    titulo: String,
    conteudo: String,
    _estado: std::marker::PhantomData<Estado>,
}

impl Artigo<Rascunho> {
    pub fn novo(titulo: String) -> Self {
        Self {
            titulo,
            conteudo: String::new(),
            _estado: std::marker::PhantomData,
        }
    }

    pub fn adicionar_texto(&mut self, texto: &str) {
        self.conteudo.push_str(texto);
    }

    // Transição de estado: consome o rascunho e devolve um artigo publicado
    pub fn publicar(self) -> Result<Artigo<Publicado>, &'static str> {
        if self.conteudo.trim().is_empty() {
            return Err("Não é possível publicar artigo sem conteúdo!");
        }
        Ok(Artigo {
            titulo: self.titulo,
            conteudo: self.conteudo,
            _estado: std::marker::PhantomData,
        })
    }
}

impl Artigo<Publicado> {
    // Este método SÓ existe se o artigo já foi publicado!
    pub fn renderizar_html(&self) -> String {
        format!("<h1>{}</h1><p>{}</p>", self.titulo, self.conteudo)
    }
}

fn main() {
    let mut rascunho = Artigo::novo("Modelo Rico em Rust".into());
    rascunho.adicionar_texto("Conteúdo de alta relevância.");

    // ❌ Erro de compilação se tentar: rascunho.renderizar_html();
    // O compilador avisa: método 'renderizar_html' não existe para Artigo<Rascunho>!

    let publicado = rascunho.publicar().expect("Publicação falhou");
    println!("{}", publicado.renderizar_html()); // ✅ Perfeito!
}
```

---

## 7. Síntese e Boas Práticas

1. **Evite `pub` irrestrito em structs de domínio:** Se qualquer parte do código pode mudar um campo de fora, você tem um modelo anêmico.
2. **Elimine *Setters* mecânicos:** Prefira métodos orientados a intenções de negócio (`matricular_aluno`, `conceder_desconto`, `cancelar_pedido`).
3. **Use *Smart Constructors* (`new` / `parse`):** Retorne `Result<Self, DomainError>` para que nunca existam entidades com dados inconsistentes em memória.
4. **Isole DTOs das Entidades:** DTOs pertencem à borda da aplicação (rede, formulários, payloads JSON); Entidades pertencem ao núcleo de domínio (*Clean Architecture*). Faça a travessia com `TryFrom`.
5. **Abrace o *Parse, Don't Validate*:** Transforme tipos primitivos vagos (`String`, `i32`) em *Value Objects* com semântica rica (`Email`, `Dinheiro`, `CpfCnpj`).
