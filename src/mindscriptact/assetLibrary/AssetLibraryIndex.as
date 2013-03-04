package mindscriptact.assetLibrary {
import flash.events.EventDispatcher;
import flash.utils.Dictionary;
import mindscriptact.assetLibrary.assets.*;
import mindscriptact.assetLibrary.core.AssetDefinition;
import mindscriptact.assetLibrary.core.AssetType;
import mindscriptact.assetLibrary.core.namespaces.assetlibrary;
import mindscriptact.assetLibrary.core.xml.XMLDefinition;

/**
 * COMMENT
 * @author Raimundas Banevicius
 */
public class AssetLibraryIndex extends EventDispatcher {
	
	private var assetIndex:Dictionary = new Dictionary(); /** of AssetDefinition by String */
	private var pathIndex:Dictionary = new Dictionary(); /** of String by String */
	private var dynamicPathAssetTypes:Dictionary = new Dictionary(); /** of String by String */
	private var groupIndex:Dictionary = new Dictionary(); /** of Vector.<String> by String */
	//
	private var xmlFileDefinitions:Dictionary = new Dictionary(); /** of XMLDefinition by String */
	private var errorHandler:Function;
	//	
	internal var xmlFilesTotal:int = 0;
	internal var xmlFilesLoaded:int = 0;
	//
	internal var canAddPermanents:Boolean = true;
	internal var libraryLaderLoadXmlFunction:Function;
	
	public function AssetLibraryIndex(errorHandler:Function) {
		this.errorHandler = errorHandler;
	}
	
	static public function setRootPath(rootPath:String):void {
		use namespace assetlibrary;
		AssetLibraryLoader.rootPath = rootPath;
	}
	
	/**
	 * Adds file definition for later us.
	 * @param	assetId		unique file id to use for adressing the file
	 * @param	fileUrl		full path to the file or just name if you use pathId
	 * @param	pathId		pathId of path definition for location there this file is.
	 * @param	permanent	Treat file as pernament asset, or temporal.
	 * @param	urlParams	url parameters that must be used then file is loaded.
	 * @param	assetType	if you use not standart file extention, you can define asset type here, if extention is standart AssetLybrary automaticaly sets the type.
	 */
	public function addFileDefinition(assetId:String, fileUrl:String, pathId:String = null, permanent:Boolean = false, urlParams:String = null, assetType:String = null):void {
		use namespace assetlibrary;
		var filePath:String = "";
		// error checking.
		if (!assetId) {
			errorHandler(Error("AssetLibraryIndex.addFileDefinition failed : assetId must be defined." + "[assetId:" + assetId + " fileName:" + fileUrl + " assetType:" + assetType + " pathId:" + pathId + "]"));
		}
		//if (!fileUrl) {
		//errorHandler(Error("AssetLibraryIndex.addFileDefinition failed : fileName must be defined." + "[assetId:" + assetId + " fileName:" + fileUrl + " assetType:" + assetType + " pathId:" + pathId + "]"));
		//}
		
		// path handling
		if (pathId) {
			if (pathIndex[pathId]) {
				filePath += pathIndex[pathId];
			} else {
				errorHandler(Error("AssetLibraryIndex.addFileDefinition failed : path with id:" + pathId + " is not defined."));
			}
		}
		filePath += fileUrl;
		
		// extentien handling
		if (!assetType) {
			//errorHandler(Error("AssetLibraryIndex.addFileDefinition failed : assetType must be defined." + "[assetId:" + assetId + " fileName:" + fileName + " assetType:" + assetType + " pathId:" + pathId + "]"));
			var nameSplit:Array = fileUrl.split(".");
			assetType = nameSplit[nameSplit.length - 1];
		}
		
		// handle urlParams
		if (urlParams) {
			filePath += urlParams;
		}
		
		addAssetDefinition(new AssetDefinition(assetId, filePath, assetType, permanent));
	}
	
	/**
	 * For convieneance enstead of writing full path with every file, its possible to assing id to the path and use id instead of full path with file definitions.
	 * @param	pathId	unique path ide
	 * @param	path	path that will be linked with pathId
	 */
	public function addPathDefinition(pathId:String, url:String, dynamicPathAssetType:String = null):void {
		if (!pathIndex[pathId]) {
			// ensure that path ends with "/" or "\" character.
			var lastLetter:String = url.charAt(url.length - 1);
			if (lastLetter != "/" && lastLetter != "\\") {
				url += "/";
			}
			pathIndex[pathId] = url;
			if (dynamicPathAssetType) {
				dynamicPathAssetTypes[pathId] = dynamicPathAssetType;
			}
		} else {
			if (pathIndex[pathId] != url) {
				errorHandler(Error("AssetLibraryIndex.addPathDefinition failed : url with same pathId:" + pathId + " can be defined only once."));
			}
		}
	}
	
	/**
	 * Adds file, path, group definitiens from xml file. XML file is loaded and parsed automaticaly. To track loading progress use AssetLibraryLoader object.(You can get it AssetLibrary.getLoader());
	 * @param	xmlPath		path of xml that holds
	 */
	public function addDefinitionsFromXML(xmlPath:String):void {
		use namespace assetlibrary;
		//if (!assetId){
		var assetId:String = "$_xmlDefinition" + xmlFilesTotal;
		//}
		var xmlAssetDefinition:AssetDefinition = new AssetDefinition(assetId, xmlPath, AssetType.XML, false);
		addAssetDefinition(xmlAssetDefinition);
		xmlAssetDefinition.isAssetXmlFile = true;
		if (!xmlFileDefinitions[assetId]) {
			xmlFileDefinitions[assetId] = new XMLDefinition(assetId);
			xmlFilesTotal++;
			libraryLaderLoadXmlFunction(assetIndex[assetId]);
		} else {
			if ((assetIndex[assetId] as AssetDefinition).filePath != xmlPath) {
				errorHandler(Error("AssetLibraryIndex.addDefinitionsFromXML failed. Different XML definition with assetId:" + assetId + " exists."));
			}
		}
	}
	
	//----------------------------------
	//     groups
	//----------------------------------
	
	/**
	 * Add one assetId to groupId. Groups are used to load or unload group af assets. (asset ids cant be removed from groups, if you have a need - create 2 diferent groups.)
	 * @param	groupId		unique group id.
	 * @param	assetId		asset id to be added to group.
	 */
	public function addAssetToGroup(groupId:String, assetId:String):void {
		if (!groupIndex[groupId]) {
			groupIndex[groupId] = new Vector.<String>();
		}
		groupIndex[groupId].push(assetId);
	}
	
	/**
	 * Add array of assetIds to groupId. Groups are used to load or unload group af assets. (asset ids cant be removed from groups, if you have a need - create 2 diferent groups.)
	 * @param	groupId		unique group id.
	 * @param	assetIds	vector of asset ids to be added to group.
	 */
	public function addAssetArrayToGroup(groupId:String, assetIds:Array):void {
		for (var i:int = 0; i < assetIds.length; i++) {
			addAssetToGroup(groupId, assetIds[i]);
		}
	}
	
	//----------------------------------
	//     INTERNAL
	//----------------------------------
	
	/**
	 * Checks if asset with specified id is already loaded.
	 * @param	assetId		asset id to check if its loaded
	 * @return	true if specified asset is loaded.
	 */
	internal function assetIsLoaded(assetId:String):Boolean {
		use namespace assetlibrary;
		var retVal:Boolean = false;
		if (assetIndex[assetId]) {
			retVal = (assetIndex[assetId] as AssetDefinition).isLoaded;
		}
		return retVal;
	}
	
	internal function getPathType(pathId:String):String {
		return dynamicPathAssetTypes[pathId];
	}
	
	private function addAssetDefinition(assetDefinition:AssetDefinition):void {
		use namespace assetlibrary;
		if (!assetIndex[assetDefinition.assetId]) {
			if (assetDefinition.isPermanent && !canAddPermanents) {
				errorHandler(Error("AssetLibraryIndex.addFileDefinition failed : AssetId " + assetDefinition.assetId + " is permanent asset, you can add those only before starting permanent asset preload. If you want to disable this protection - set AssetLibrary.isPermanentsProtected = false;"));
			}
			assetIndex[assetDefinition.assetId] = assetDefinition;
			//
			var asset:AssetAbstract;
			switch (assetDefinition.type) {
				case AssetType.SWF: 
					asset = new SwfAsset(assetDefinition.assetId);
					break;
				case AssetType.JPG: 
				case AssetType.PNG: 
				case AssetType.GIF: 
					asset = new PicAsset(assetDefinition.assetId);
					break;
				case AssetType.MP3: 
					asset = new Mp3Asset(assetDefinition.assetId);
					break;
				case AssetType.XML: 
					asset = new XmlAsset(assetDefinition.assetId);
					break;
				default: 
					trace("AssetLibraryLoader can't handle this type yet. Asset type:", assetDefinition.type);
					break;
			}
			assetDefinition.asset = asset;
		} else {
			var currentAssetDefinition:AssetDefinition = assetIndex[assetDefinition.assetId];
			if (currentAssetDefinition.filePath != assetDefinition.filePath || currentAssetDefinition.isPermanent != assetDefinition.isPermanent) {
				errorHandler(Error("AssetLibraryIndex.addFileDefinition failed : AssetId " + assetDefinition.assetId + " is already taken, and new definiiton is diferent from already existing one. Unload it or use another assedId, or use same asset definition if you have same assetId in more then one place."));
			}
		}
	}
	
	internal function getAssetDefinition(assetId:String):AssetDefinition {
		use namespace assetlibrary;
		if (assetIndex[assetId]) {
			return assetIndex[assetId];
		} else {
			return null;
		}
	}
	
	internal function getAsset(assetId:String):AssetAbstract {
		use namespace assetlibrary;
		if (!assetIndex[assetId]) {
			errorHandler(Error("AssetLibraryIndex.getAsset failed. Asset with assetId:" + assetId + " is not created."));
			return null;
		}
		return (assetIndex[assetId] as AssetDefinition).asset;
	}
	
	internal function getAssetsForPreloading():Vector.<AssetDefinition> {
		use namespace assetlibrary;
		var retVal:Vector.<AssetDefinition> = new Vector.<AssetDefinition>();
		for each (var assetDefinition:AssetDefinition in assetIndex) {
			if (!assetDefinition.isLoaded && assetDefinition.isPermanent) {
				retVal.push(assetDefinition);
			}
		}
		return retVal;
	}
	
	internal function getGroupAssets(groupId:String):Vector.<String> {
		if (!groupIndex[groupId]) {
			errorHandler(Error("AssetLibraryIndex.getGroupAssets failed. Asset group with groupId:" + groupId + " is not created."));
		}
		return groupIndex[groupId];
	}
	
	internal function getAllSoundAssets():Vector.<Mp3Asset> {
		use namespace assetlibrary;
		var retVal:Vector.<Mp3Asset> = new Vector.<Mp3Asset>();
		for each (var assetDefinition:AssetDefinition in assetIndex) {
			if (assetDefinition.asset && assetDefinition.asset is Mp3Asset) {
				retVal.push(assetDefinition.asset);
			}
		}
		return retVal;
	}
	
	internal function getAssetIndex():Dictionary {
		return assetIndex;
	}

}
}