import UIKit

class WMFExploreWrapperViewController: UIViewController {
    
//    @IBOutlet weak var exploreViewController: WMFExploreViewController!
    
    private var exploreViewController: WMFExploreViewController?
    
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//    }
    
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
         super.init(coder: aDecoder)
        
       // exploreViewController = nil
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier,
            identifier == "embedCollectionViewController" else {
                return
        }
        guard let vc = segue.destination as? WMFExploreViewController else {
            assertionFailure("should be a WMFExploreViewController")
            return
        }
        
        exploreViewController = vc
    }
    
}
