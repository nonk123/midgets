class InitStatics : EventHandler {
    override void NewGame() {
        MaterialType.Populate();
        RecipeType.Populate();
    }
}
