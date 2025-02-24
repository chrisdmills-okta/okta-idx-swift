//
// Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
// The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
//
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//
// See the License for the specific language governing permissions and limitations under the License.
//

import Foundation

extension IDXClient {
    /// Provides information about the client application being authenticated against.
    @objc(IDXApplication)
    public class Application: NSObject {
        /// Unique identifier for this application.
        @objc(identifier)
        public let id: String
        
        /// Label for this application.
        @objc public let label: String
        
        /// Name for this application.
        @objc public let name: String
        
        internal init(id: String, label: String, name: String) {
            self.id = id
            self.label = label
            self.name = name
         
            super.init()
        }
        
        public override var description: String {
            let logger = DebugDescription(self)
            let components = [
                logger.address(),
                "\(#keyPath(id)): \(id)",
                "\(#keyPath(label)): \(label)",
                "\(#keyPath(name)): \(name)",
            ]
            
            return logger.brace(components.joined(separator: "; "))
        }
        
        public override var debugDescription: String {
            description
        }
    }
}
