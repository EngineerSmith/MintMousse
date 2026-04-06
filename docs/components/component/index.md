# Component
The object you use to update the components on the web console. It is also known as a `Proxy Table`.

## Constructors
|Constructors|Description
|---|---|
|[`mintmousse.newTab`](../newTab.md)|Create a new Tab|
|[`(Component):new`](new.md)|Create a new component|

## Functions
|Function|Description|
|---|---|
|[`(Component):add`](add.md)|Create a new component|
|[`(Component):remove`](remove.md)|Removes itself, and it's children if any|
|[`(Component):setChildrenOrder`](setChildrenOrder.md)|Set the order of all the children at once|
|[`(Component):moveBefore`](moveBefore.md)|Move the current component before the given component|
|[`(Component):moveAfter`](moveAfter.md)|Move the current component after the given component|
|[`(Component):moveToFront`](moveToFront.md)|Move the component to the 1st index|
|[`(Component):moveToBack`](moveToBack.md)|Move the component to the last index|
|[`(Component):children](children.md)|Used to iterate over all the locally known children|

## Fields
|Field|Description|
|---|---|
|`(Component).id`|The ID of the component, one is generated if one isn't given|
|`(Component).type`|The type of the component, or **"unknown"** if it isn't known|
|`(Component).parentID`|The parent ID of the component, if the local thread knows it|
|[`(Component).parent`](parent.md)|Get the parent component of this component|
|[`(Component).back`](back.md)|Syntax sugar: alias for [`(Component).parent`](parent.md)|
|`(Component).isDead`|Has this component marked removed.|

## See Also
- [Components](../index.md)