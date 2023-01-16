class InitStatics : EventHandler {
    override void NewGame() {
        Material.Populate();
        Recipe.Populate();
    }
}
