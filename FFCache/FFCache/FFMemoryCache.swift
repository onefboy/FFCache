//
//  FFMemoryCache.swift
//  FFCache
//
//  Created by json.wang on 2019/3/19.
//  Copyright © 2019年 onefboy. All rights reserved.
//

import UIKit

public class FFMemoryCache: NSObject, NSCacheDelegate {
  
  private var cache: NSCache<AnyObject, AnyObject>!
  private var totalCost: Int = 0// 限定缓存空间的最大内存 单位是字节Byte，超出上限会自动回收对象，默认值是0，表示没有限制
  private var totalCount: Int = 0// 限定了缓存最多维护的对象的个数。默认值为0，表示没有限制
  private var memoryQueue: DispatchQueue!
  
  public static let shared: FFMemoryCache = {
    let memory = FFMemoryCache()
    memory.cache = NSCache()
    memory.cache.totalCostLimit = memory.totalCost
    memory.cache.countLimit = memory.totalCount
    memory.cache.delegate = memory.self
    memory.memoryQueue = DispatchQueue(label: "com.onefboy.ffcache.memory")
    return memory
  }()
  
  private override init() {}
  
  public func setTotalCost(_ cost: Int) {
    totalCost = cost
    cache.totalCostLimit = totalCost
  }
  
  public func setTotalCount(_ count: Int) {
    totalCount = count
    cache.countLimit = totalCount
  }
  
  private func hasCache(forKey key: String) -> Bool {
    if cache.object(forKey: key as AnyObject) != nil {
      return true
    }
    return false
  }
  
  // MARK: - Public Asynchronous Methods
  public func removeAllObjects(_ block: @escaping ((FFMemoryCache) -> Void)) {
    memoryQueue.async {
      self.cache.removeAllObjects()
      block(self)
    }
  }
  
  public func removeObject(forKey key: String, block: @escaping ((FFMemoryCache, String, Any?) -> Void)) {
    memoryQueue.async {
      
      var object: Any?
      
      if self.hasCache(forKey: key) {
        object = self.cache.object(forKey: key as AnyObject) as Any
      }
      self.cache.removeObject(forKey: key as AnyObject)
      
      block(self, key, object)
    }
  }
  
  public func object(forKey key: String, block: @escaping ((FFMemoryCache, String, Any?) -> Void)) {
    memoryQueue.async {
      var object: Any?
      
      if self.hasCache(forKey: key) {
        object = self.cache.object(forKey: key as AnyObject) as Any
      }
      
      block(self, key, object)
    }
  }
  
  public func setObject(_ object: Codable, forKey key: String, block: @escaping ((FFMemoryCache, String, Any?) -> Void)) {
    memoryQueue.async {
      self.cache.setObject(object as AnyObject, forKey: key as AnyObject, cost: self.totalCost)
      block(self, key, object)
    }
  }
  
  // MARK: - Public Synchronous Methods
  public func removeAllObjects() {
    cache.removeAllObjects()
  }
  
  public func removeObject(forKey key: String) {
    cache.removeObject(forKey: key as AnyObject)
  }
  
  public func object(forKey key: String) -> Any? {
    if hasCache(forKey: key) {
      return cache.object(forKey: key as AnyObject)
    }
    return nil
  }
  
  public func setObject(_ object: Codable, forKey key: String) {
    cache.setObject(object as AnyObject, forKey: key as AnyObject, cost: totalCost)
  }
  
  // MARK: - NSCacheDelegate
  private func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    #if DEBUG
      print("FFMemoryCache：回收对象--------\(obj)");
    #else
      // TODO
    #endif
  }
}
