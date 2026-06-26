# PantherLang Syntax Guide

## Application

```panther
app PantherStore {
    version "0.5"
}
```

## Model

```panther
model Product {
    id: uuid
    title: string required
    price: decimal required
}
```

## API

```panther
api GET /products {
    public
    return Product.all()
}
```

## Page

```panther
page Products {
    title "Products"
    table Product
}
```

## Agent

```panther
agent Assistant {
    purpose "Help users"
    tools data, api
    memory scoped
}
```

## Capabilities

```panther
capabilities {
    network allow local
    filesystem allow app_storage
}
```
