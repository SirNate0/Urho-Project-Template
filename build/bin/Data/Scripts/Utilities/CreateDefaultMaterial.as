// This file exists to update the DefaultMaterial.xml contained in the Docs/ folder.
// To use navigate to Docs/ in the source tree and run this script with Urho3DPlayer
// Default values are set in the constructor, so we can just construct and save a material

void Start()
{
    Material@ mat = Material();
    mat.Save("DefaultMaterial.xml");
    Print("Saved default material to DefaultMat.xml");
    engine.Exit();
}
